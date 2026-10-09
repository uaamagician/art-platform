import { readFileSync } from 'node:fs';
import {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} from '@firebase/rules-unit-testing';
import {
  doc, getDoc, setDoc, updateDoc, deleteDoc, writeBatch, runTransaction,
  increment, serverTimestamp, arrayUnion, arrayRemove, collection, addDoc,
} from 'firebase/firestore';
import { ref, uploadBytes, getBytes, deleteObject } from 'firebase/storage';

const testEnv = await initializeTestEnvironment({
  projectId: 'demo-art-platform',
  firestore: { rules: readFileSync('firestore.rules', 'utf8'), host: '127.0.0.1', port: 8085 },
  storage: { rules: readFileSync('storage.rules', 'utf8'), host: '127.0.0.1', port: 9199 },
});

let passed = 0;
let failed = 0;
async function check(name, fn) {
  try {
    await fn();
    passed++;
    console.log(`  PASS  ${name}`);
  } catch (e) {
    failed++;
    console.log(`  FAIL  ${name}\n        ${String(e.message).split('\n')[0]}`);
  }
}

async function seed() {
  await testEnv.clearFirestore();
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(doc(db, 'users/alice'), { displayName: 'Alice', email: 'a@x.com', showNsfw: false });
    await setDoc(doc(db, 'profiles/alice'), { displayName: 'Alice', bio: 'hi', postCount: 1, createdAt: 1 });
    await setDoc(doc(db, 'profiles/bob'), { displayName: 'Bob', bio: '', postCount: 0, createdAt: 1 });
    await setDoc(doc(db, 'posts/p1'), {
      userId: 'alice', title: 'hello', isNsfw: false, isAiGenerated: false,
      likesCount: 0, commentsCount: 0, tags: ['a'], category: 'x',
    });
    // legacy post written by the very first app version: no counters at all
    await setDoc(doc(db, 'posts/legacy'), { userId: 'alice', title: 'old', imageUrl: 'u' });
    await setDoc(doc(db, 'categories/c1'), { name: 'x', order: 0 });
    await setDoc(doc(db, 'commissions/c1'), {
      userId: 'alice', type: 'request', title: 'Need a logo', description: '', contact: 'line:alice',
      isNsfw: false, status: 'open', reportCount: 0,
    });
    await setDoc(doc(db, 'commissions/c2'), {
      userId: 'alice', type: 'offer', title: 'Reported', description: '', contact: 'x',
      isNsfw: false, status: 'open', reportCount: 2,
    });
    await setDoc(doc(db, 'consults/k1'), {
      userId: 'alice', title: 'Fix my anatomy', imageUrl: 'u', floorsCount: 0,
    });
    await setDoc(doc(db, 'groups/g1'), {
      name: 'Sketch club', description: '', ownerId: 'alice', memberIds: ['alice', 'bob'], locked: false, lastMessage: '',
    });
  });
}

const validPost = (uid, extra = {}) => ({
  userId: uid, userName: uid, title: 'My art', description: '', imageUrl: 'u', imageUrls: ['u'],
  attachments: [], category: 'x', tags: ['t'], isNsfw: false, isAiGenerated: true,
  likesCount: 0, commentsCount: 0, createdAt: serverTimestamp(), ...extra,
});

const as = (uid) => testEnv.authenticatedContext(uid).firestore();
const alice = () => as('alice');
const bob = () => as('bob');
const carol = () => as('carol');
const guest = () => testEnv.unauthenticatedContext().firestore();

console.log('\n== Posts: read & create ==');
await seed();
await check('guest can read posts', () => assertSucceeds(getDoc(doc(guest(), 'posts/p1'))));
await check('guest can read categories', () => assertSucceeds(getDoc(doc(guest(), 'categories/c1'))));
await check('guest cannot create a post', () => assertFails(setDoc(doc(guest(), 'posts/g1'), validPost('alice'))));
await check('alice creates a valid post', () => assertSucceeds(setDoc(doc(alice(), 'posts/n1'), validPost('alice'))));
await check('post without isNsfw is rejected', () => {
  const p = validPost('alice'); delete p.isNsfw;
  return assertFails(setDoc(doc(alice(), 'posts/n2'), p));
});
await check('post without isAiGenerated is rejected', () => {
  const p = validPost('alice'); delete p.isAiGenerated;
  return assertFails(setDoc(doc(alice(), 'posts/n3'), p));
});
await check('non-boolean label is rejected', () => assertFails(setDoc(doc(alice(), 'posts/n4'), validPost('alice', { isNsfw: 'no' }))));
await check('cannot post as someone else', () => assertFails(setDoc(doc(alice(), 'posts/n5'), validPost('bob'))));
await check('empty title rejected', () => assertFails(setDoc(doc(alice(), 'posts/n6'), validPost('alice', { title: '' }))));
await check('51-char title rejected', () => assertFails(setDoc(doc(alice(), 'posts/n7'), validPost('alice', { title: 'x'.repeat(51) }))));
await check('cannot start with fake likesCount', () => assertFails(setDoc(doc(alice(), 'posts/n9'), validPost('alice', { likesCount: 99 }))));

console.log('\n== Posts: update & delete ==');
await seed();
await check('owner can edit own post', () => assertSucceeds(updateDoc(doc(alice(), 'posts/p1'), { title: 'edited', tags: ['b'] })));
await check('stranger cannot edit title', () => assertFails(updateDoc(doc(bob(), 'posts/p1'), { title: 'hacked' })));
await check('stranger cannot flip NSFW label', () => assertFails(updateDoc(doc(bob(), 'posts/p1'), { isNsfw: true })));
await check('stranger cannot bump likesCount without a like doc', () => assertFails(updateDoc(doc(bob(), 'posts/p1'), { likesCount: increment(1) })));
await check('stranger cannot bump likesCount by 5', () => assertFails(updateDoc(doc(bob(), 'posts/p1'), { likesCount: increment(5) })));
await check('guest cannot change likesCount', () => assertFails(updateDoc(doc(guest(), 'posts/p1'), { likesCount: increment(1) })));
await check('stranger cannot delete post', () => assertFails(deleteDoc(doc(bob(), 'posts/p1'))));
await check('owner can delete post', () => assertSucceeds(deleteDoc(doc(alice(), 'posts/p1'))));

console.log('\n== Likes (same transaction the app uses) ==');
await seed();
const likeTx = (db, uid, postId) => runTransaction(db, async (tx) => {
  const likeRef = doc(db, `posts/${postId}/likes/${uid}`);
  const snap = await tx.get(likeRef);
  const post = doc(db, `posts/${postId}`);
  const profile = doc(db, `profiles/${uid}`);
  if (snap.exists()) {
    tx.delete(likeRef);
    tx.delete(doc(db, `users/${uid}/liked/${postId}`));
    tx.update(post, { likesCount: increment(-1) });
    tx.set(profile, { likedCount: increment(-1) }, { merge: true });
  } else {
    tx.set(likeRef, { likedAt: serverTimestamp() });
    tx.set(doc(db, `users/${uid}/liked/${postId}`), { postId, tags: ['a'], category: 'x', createdAt: serverTimestamp() });
    tx.update(post, { likesCount: increment(1) });
    tx.set(profile, { likedCount: increment(1) }, { merge: true });
  }
});
await check('bob likes alice\'s post', () => assertSucceeds(likeTx(bob(), 'bob', 'p1')));
await check('like count is now 1', async () => {
  const snap = await assertSucceeds(getDoc(doc(bob(), 'posts/p1')));
  if (snap.data().likesCount !== 1) throw new Error(`likesCount=${snap.data().likesCount}`);
});
await check('bob unlikes', () => assertSucceeds(likeTx(bob(), 'bob', 'p1')));
await check('bob likes a legacy post that has no counters', () => assertSucceeds(likeTx(bob(), 'bob', 'legacy')));
await check('bob cannot like on behalf of alice', () => assertFails(setDoc(doc(bob(), 'posts/p1/likes/alice'), { likedAt: serverTimestamp() })));
await check('guest cannot like', () => assertFails(setDoc(doc(guest(), 'posts/p1/likes/x'), { likedAt: serverTimestamp() })));
await check('bob cannot write into alice\'s "liked" mirror', () => assertFails(setDoc(doc(bob(), 'users/alice/liked/p1'), { postId: 'p1' })));
await check('bob cannot double-count: like doc + count +2', () => {
  const db = bob();
  const b = writeBatch(db);
  b.set(doc(db, 'posts/p1/likes/bob'), { likedAt: serverTimestamp() });
  b.update(doc(db, 'posts/p1'), { likesCount: increment(2) });
  return assertFails(b.commit());
});

console.log('\n== Comments ==');
await seed();
const commentBatch = (db, uid, cid, extra = {}) => {
  const b = writeBatch(db);
  b.set(doc(db, `posts/p1/comments/${cid}`), { userId: uid, userName: uid, text: 'nice', createdAt: serverTimestamp(), ...extra });
  b.update(doc(db, 'posts/p1'), { commentsCount: increment(1) });
  b.set(doc(db, `profiles/${uid}`), { commentCount: increment(1) }, { merge: true });
  return b.commit();
};
await check('bob comments (batch + commentsCount + profile counter)', () => assertSucceeds(commentBatch(bob(), 'bob', 'c1')));
await check('guest can read comments', () => assertSucceeds(getDoc(doc(guest(), 'posts/p1/comments/c1'))));
await check('guest cannot comment', () => assertFails(setDoc(doc(guest(), 'posts/p1/comments/g'), { userId: 'x', text: 'hi' })));
await check('cannot comment as someone else', () => assertFails(commentBatch(bob(), 'alice', 'c2')));
await check('empty comment rejected', () => assertFails(commentBatch(bob(), 'bob', 'c3', { text: '' })));
await check('501-char comment rejected', () => assertFails(commentBatch(bob(), 'bob', 'c4', { text: 'x'.repeat(501) })));
await check('stranger cannot set commentsCount to 50', () => assertFails(updateDoc(doc(bob(), 'posts/p1'), { commentsCount: 50 })));
await check('third party cannot delete bob\'s comment', () => assertFails(deleteDoc(doc(carol(), 'posts/p1/comments/c1'))));
await check('post author can delete any comment', () => assertSucceeds(deleteDoc(doc(alice(), 'posts/p1/comments/c1'))));
await check('comment cannot be edited', () => assertFails(updateDoc(doc(bob(), 'posts/p1/comments/c5'), { text: 'x' })));

console.log('\n== Profiles & follows (same batch the app uses) ==');
await seed();
const followBatch = (db, me, target, follow) => {
  const b = writeBatch(db);
  const mine = doc(db, `profiles/${me}/following/${target}`);
  const theirs = doc(db, `profiles/${target}/followers/${me}`);
  if (follow) {
    b.set(mine, { createdAt: serverTimestamp() });
    b.set(theirs, { createdAt: serverTimestamp() });
  } else {
    b.delete(mine);
    b.delete(theirs);
  }
  return b.commit();
};
await check('guest can read profiles', () => assertSucceeds(getDoc(doc(guest(), 'profiles/alice'))));
await check('guest can read follower lists', () => assertSucceeds(getDoc(doc(guest(), 'profiles/alice/followers/bob'))));
await check('bob follows alice', () => assertSucceeds(followBatch(bob(), 'bob', 'alice', true)));
await check('bob follows a user who has no profile doc yet', () => assertSucceeds(followBatch(bob(), 'bob', 'dave', true)));
await check('bob unfollows alice', () => assertSucceeds(followBatch(bob(), 'bob', 'alice', false)));
await check('bob cannot edit alice\'s bio', () => assertFails(updateDoc(doc(bob(), 'profiles/alice'), { bio: 'hacked' })));
await check('bob cannot make carol follow alice', () => assertFails(setDoc(doc(bob(), 'profiles/alice/followers/carol'), { createdAt: serverTimestamp() })));
await check('bob cannot make alice follow someone', () => assertFails(setDoc(doc(bob(), 'profiles/alice/following/carol'), { createdAt: serverTimestamp() })));
await check('guest cannot follow', () => assertFails(setDoc(doc(guest(), 'profiles/alice/followers/x'), { createdAt: serverTimestamp() })));
await check('alice can edit her own bio', () => assertSucceeds(setDoc(doc(alice(), 'profiles/alice'), { bio: 'new bio' }, { merge: true })));
await check('a 81-char bio is rejected', () => assertFails(setDoc(doc(alice(), 'profiles/alice'), { bio: 'x'.repeat(81) }, { merge: true })));
await check('alice can create her profile', () => assertSucceeds(setDoc(doc(as('zoe'), 'profiles/zoe'), { displayName: 'Zoe', createdAt: serverTimestamp() })));

console.log('\n== Private account data ==');
await seed();
await check('owner can read own users doc', () => assertSucceeds(getDoc(doc(alice(), 'users/alice'))));
await check('guest cannot read users doc (has email)', () => assertFails(getDoc(doc(guest(), 'users/alice'))));
await check('other user cannot read users doc', () => assertFails(getDoc(doc(bob(), 'users/alice'))));
await check('other user cannot write users doc', () => assertFails(setDoc(doc(bob(), 'users/alice'), { showNsfw: true }, { merge: true })));
await check('owner can toggle content filter', () => assertSucceeds(setDoc(doc(alice(), 'users/alice'), { showNsfw: true, showAi: true }, { merge: true })));
await check('user can bookmark', () => assertSucceeds(setDoc(doc(bob(), 'users/bob/bookmarks/p1'), { postId: 'p1', createdAt: serverTimestamp() })));
await check('nobody else can read bob\'s bookmarks', () => assertFails(getDoc(doc(alice(), 'users/bob/bookmarks/p1'))));
await check('signed-in user can bump tag usage', () => assertSucceeds(setDoc(doc(bob(), 'tags/光影'), { name: '光影', usageCount: increment(1), type: 'custom' }, { merge: true })));
await check('guest cannot write tags', () => assertFails(setDoc(doc(guest(), 'tags/x'), { name: 'x' })));

console.log('\n== Full publish batch ==');
await seed();
await check('publish batch succeeds', () => {
  const db = alice();
  const b = writeBatch(db);
  b.set(doc(db, 'posts/full1'), validPost('alice'));
  b.set(doc(db, 'profiles/alice'), { postCount: increment(1) }, { merge: true });
  b.set(doc(db, 'tags/t'), { name: 't', usageCount: increment(1), type: 'custom' }, { merge: true });
  return b.commit();
});
await check('publish batch is rejected when labels are missing', () => {
  const db = alice();
  const p = validPost('alice'); delete p.isAiGenerated;
  const b = writeBatch(db);
  b.set(doc(db, 'posts/full2'), p);
  return assertFails(b.commit());
});

console.log('\n== Commissions ==');
await seed();
const validCommission = (uid, extra = {}) => ({
  userId: uid, userName: uid, type: 'request', title: 'Character art', description: 'details',
  category: '數位繪圖', tags: ['oc'], budgetText: 'NT$1000', contact: 'IG: @me', imageUrls: [],
  isNsfw: false, status: 'open', reportCount: 0, createdAt: serverTimestamp(), ...extra,
});
await check('guest can read commissions', () => assertSucceeds(getDoc(doc(guest(), 'commissions/c1'))));
await check('guest cannot create a commission', () => assertFails(setDoc(doc(guest(), 'commissions/n1'), validCommission('alice'))));
await check('bob creates a request', () => assertSucceeds(setDoc(doc(bob(), 'commissions/n1'), validCommission('bob'))));
await check('bob creates an offer', () => assertSucceeds(setDoc(doc(bob(), 'commissions/n2'), validCommission('bob', { type: 'offer' }))));
await check('unknown type rejected', () => assertFails(setDoc(doc(bob(), 'commissions/n3'), validCommission('bob', { type: 'scam' }))));
await check('contact is required', () => assertFails(setDoc(doc(bob(), 'commissions/n4'), validCommission('bob', { contact: '' }))));
await check('missing NSFW label rejected', () => {
  const c = validCommission('bob'); delete c.isNsfw;
  return assertFails(setDoc(doc(bob(), 'commissions/n5'), c));
});
await check('cannot create with a non-zero reportCount', () => assertFails(setDoc(doc(bob(), 'commissions/n6'), validCommission('bob', { reportCount: 3 }))));
await check('cannot create as someone else', () => assertFails(setDoc(doc(bob(), 'commissions/n7'), validCommission('alice'))));
await check('owner can close their commission', () => assertSucceeds(updateDoc(doc(alice(), 'commissions/c1'), { status: 'closed' })));
await check('owner cannot reset reportCount', () => assertFails(updateDoc(doc(alice(), 'commissions/c2'), { reportCount: 0 })));
await check('stranger cannot close someone else\'s commission', () => assertFails(updateDoc(doc(bob(), 'commissions/c1'), { status: 'closed' })));
const reportCommission = (db, uid, cid) => {
  const b = writeBatch(db);
  b.set(doc(db, `reports/commission_${cid}_${uid}`), {
    targetType: 'commission', targetId: cid, reporterId: uid, reason: '詐騙或可疑', createdAt: serverTimestamp(),
  });
  b.update(doc(db, `commissions/${cid}`), { reportCount: increment(1) });
  return b.commit();
};
await check('bob reports a commission (report doc + counter)', () => assertSucceeds(reportCommission(bob(), 'bob', 'c1')));
await check('bob cannot report the same commission twice', () => assertFails(reportCommission(bob(), 'bob', 'c1')));
await check('carol reports it too', () => assertSucceeds(reportCommission(carol(), 'carol', 'c1')));
await check('bumping reportCount without a report doc is rejected', () => assertFails(updateDoc(doc(as('erin'), 'commissions/c1'), { reportCount: increment(1) })));
await check('reports are not readable from the app', () => assertFails(getDoc(doc(alice(), 'reports/commission_c1_bob'))));
await check('cannot file a report under someone else\'s id', () => assertFails(setDoc(doc(bob(), 'reports/commission_c1_carol'), {
  targetType: 'commission', targetId: 'c1', reporterId: 'bob', reason: 'x', createdAt: serverTimestamp(),
})));
await check('post report is accepted', () => assertSucceeds(setDoc(doc(bob(), 'reports/post_p1_bob'), {
  targetType: 'post', targetId: 'p1', reporterId: 'bob', reason: '成人內容未標示', createdAt: serverTimestamp(),
})));
await check('stranger cannot delete a commission', () => assertFails(deleteDoc(doc(bob(), 'commissions/c1'))));
await check('owner can delete a commission', () => assertSucceeds(deleteDoc(doc(alice(), 'commissions/c1'))));

console.log('\n== Consults (蓋樓) ==');
await seed();
const addFloor = (db, uid, consultId, floorId, floor, extra = {}) => {
  const b = writeBatch(db);
  b.update(doc(db, `consults/${consultId}`), { floorsCount: increment(1) });
  b.set(doc(db, `consults/${consultId}/floors/${floorId}`), {
    floor, userId: uid, userName: uid, text: 'try this', imageUrl: '', deleted: false, createdAt: serverTimestamp(), ...extra,
  });
  return b.commit();
};
await check('guest can read consults', () => assertSucceeds(getDoc(doc(guest(), 'consults/k1'))));
await check('bob creates a consult', () => assertSucceeds(setDoc(doc(bob(), 'consults/k2'), {
  userId: 'bob', userName: 'bob', title: 'Help', description: '', imageUrl: 'u', floorsCount: 0, createdAt: serverTimestamp(),
})));
await check('consult without an image is rejected', () => assertFails(setDoc(doc(bob(), 'consults/k3'), {
  userId: 'bob', title: 'Help', imageUrl: '', floorsCount: 0,
})));
await check('bob stacks floor 1', () => assertSucceeds(addFloor(bob(), 'bob', 'k1', 'f1', 1)));
await check('carol stacks floor 2', () => assertSucceeds(addFloor(carol(), 'carol', 'k1', 'f2', 2)));
await check('author can reply on their own consult (floor 3)', () => assertSucceeds(addFloor(alice(), 'alice', 'k1', 'f3', 3)));
await check('wrong floor number is rejected', () => assertFails(addFloor(bob(), 'bob', 'k1', 'f9', 9)));
await check('cannot skip numbering (floor 5 after 3)', () => assertFails(addFloor(bob(), 'bob', 'k1', 'f5', 5)));
await check('cannot post a floor as someone else', () => assertFails(addFloor(bob(), 'alice', 'k1', 'f4', 4)));
await check('empty floor (no text, no image) rejected', () => assertFails(addFloor(bob(), 'bob', 'k1', 'f4', 4, { text: '' })));
await check('stranger cannot bump floorsCount by 2', () => assertFails(updateDoc(doc(bob(), 'consults/k1'), { floorsCount: increment(2) })));
await check('stranger cannot rewrite the title', () => assertFails(updateDoc(doc(bob(), 'consults/k1'), { title: 'x' })));
await check('floor author can blank their floor', () => assertSucceeds(updateDoc(doc(bob(), 'consults/k1/floors/f1'), { deleted: true, text: '', imageUrl: '' })));
await check('consult author can blank anyone\'s floor', () => assertSucceeds(updateDoc(doc(alice(), 'consults/k1/floors/f2'), { deleted: true, text: '', imageUrl: '' })));
await check('third party cannot blank a floor', () => assertFails(updateDoc(doc(as('erin'), 'consults/k1/floors/f3'), { deleted: true })));
await check('floors cannot be hard-deleted', () => assertFails(deleteDoc(doc(alice(), 'consults/k1/floors/f3'))));
await check('floor author cannot rewrite floor number', () => assertFails(updateDoc(doc(alice(), 'consults/k1/floors/f3'), { floor: 1 })));

console.log('\n== Groups ==');
await seed();
await check('guest cannot read groups', () => assertFails(getDoc(doc(guest(), 'groups/g1'))));
await check('signed-in user can browse groups', () => assertSucceeds(getDoc(doc(carol(), 'groups/g1'))));
await check('carol creates a group', () => assertSucceeds(setDoc(doc(carol(), 'groups/g2'), {
  name: 'Painters', description: 'oil', ownerId: 'carol', memberIds: ['carol'], locked: false, lastMessage: '', createdAt: serverTimestamp(),
})));
await check('cannot create a group owned by someone else', () => assertFails(setDoc(doc(carol(), 'groups/g3'), {
  name: 'x', description: '', ownerId: 'alice', memberIds: ['alice'], locked: false,
})));
await check('cannot create a group with extra members', () => assertFails(setDoc(doc(carol(), 'groups/g4'), {
  name: 'x', description: '', ownerId: 'carol', memberIds: ['carol', 'alice'], locked: false,
})));
await check('carol joins g1', () => assertSucceeds(updateDoc(doc(carol(), 'groups/g1'), { memberIds: arrayUnion('carol') })));
await check('carol cannot add erin as well', () => assertFails(updateDoc(doc(as('erin'), 'groups/g1'), { memberIds: arrayUnion('erin', 'frank') })));
await check('erin cannot add carol for her', () => assertFails(updateDoc(doc(as('erin'), 'groups/g1'), { memberIds: arrayUnion('zed') })));
await check('member cannot take over ownership', () => assertFails(updateDoc(doc(bob(), 'groups/g1'), { ownerId: 'bob' })));
await check('member cannot lock the board', () => assertFails(updateDoc(doc(bob(), 'groups/g1'), { locked: true })));
await check('member cannot kick another member', () => assertFails(updateDoc(doc(bob(), 'groups/g1'), { memberIds: arrayRemove('alice') })));
await check('member can leave', () => assertSucceeds(updateDoc(doc(carol(), 'groups/g1'), { memberIds: arrayRemove('carol') })));
await check('owner can kick a member', () => assertSucceeds(updateDoc(doc(alice(), 'groups/g1'), { memberIds: arrayRemove('bob') })));
await check('non-member cannot read messages', () => assertFails(getDoc(doc(bob(), 'groups/g1/messages/m0'))));
await check('rejoin as bob', () => assertSucceeds(updateDoc(doc(bob(), 'groups/g1'), { memberIds: arrayUnion('bob') })));
const sendMessage = (db, gid, uid, text) => {
  const b = writeBatch(db);
  b.set(doc(collection(db, `groups/${gid}/messages`)), { userId: uid, userName: uid, userPhotoUrl: '', text, createdAt: serverTimestamp() });
  b.update(doc(db, `groups/${gid}`), { lastMessage: text, lastMessageAt: serverTimestamp() });
  return b.commit();
};
await check('member sends a message (message + preview)', () => assertSucceeds(sendMessage(bob(), 'g1', 'bob', 'hello')));
await check('non-member cannot send a message', () => assertFails(sendMessage(as('erin'), 'g1', 'erin', 'hi')));
await check('cannot send as someone else', () => assertFails(sendMessage(bob(), 'g1', 'alice', 'hi')));
await check('empty message rejected', () => assertFails(sendMessage(bob(), 'g1', 'bob', '')));
await check('1001-char message rejected', () => assertFails(sendMessage(bob(), 'g1', 'bob', 'x'.repeat(1001))));
await check('member can read messages', () => assertSucceeds(getDoc(doc(bob(), 'groups/g1/messages/anything'))));
await check('non-member cannot rewrite the preview', () => assertFails(updateDoc(doc(as('erin'), 'groups/g1'), { lastMessage: 'spam' })));
const stroke = (uid, extra = {}) => ({ userId: uid, color: 4280000000, width: 4, points: [0.1, 0.1, 0.2, 0.2], createdAt: serverTimestamp(), ...extra });
await check('member draws a stroke', () => assertSucceeds(addDoc(collection(bob(), 'groups/g1/strokes'), stroke('bob'))));
await check('non-member cannot draw', () => assertFails(addDoc(collection(as('erin'), 'groups/g1/strokes'), stroke('erin'))));
await check('cannot draw as someone else', () => assertFails(addDoc(collection(bob(), 'groups/g1/strokes'), stroke('alice'))));
await check('stroke with one point is rejected', () => assertFails(addDoc(collection(bob(), 'groups/g1/strokes'), stroke('bob', { points: [0.1] }))));
await check('oversized stroke is rejected', () => assertFails(addDoc(collection(bob(), 'groups/g1/strokes'), stroke('bob', { points: new Array(2002).fill(0.5) }))));
await check('owner locks the board', () => assertSucceeds(updateDoc(doc(alice(), 'groups/g1'), { locked: true })));
await check('member cannot draw while locked', () => assertFails(addDoc(collection(bob(), 'groups/g1/strokes'), stroke('bob'))));
await check('owner can still draw while locked', () => assertSucceeds(addDoc(collection(alice(), 'groups/g1/strokes'), stroke('alice'))));
await check('member can undo their own stroke (delete)', async () => {
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), 'groups/g1/strokes/mine'), stroke('bob'));
    await setDoc(doc(ctx.firestore(), 'groups/g1/strokes/theirs'), stroke('alice'));
  });
  await assertSucceeds(deleteDoc(doc(bob(), 'groups/g1/strokes/mine')));
});
await check('member cannot delete someone else\'s stroke', () => assertFails(deleteDoc(doc(bob(), 'groups/g1/strokes/theirs'))));
await check('owner can clear anyone\'s stroke', () => assertSucceeds(deleteDoc(doc(alice(), 'groups/g1/strokes/theirs'))));
await check('member cannot delete the group', () => assertFails(deleteDoc(doc(bob(), 'groups/g1'))));
await check('owner can delete the group', () => assertSucceeds(deleteDoc(doc(alice(), 'groups/g1'))));

console.log('\n== Storage ==');
const alSt = () => testEnv.authenticatedContext('alice').storage();
const boSt = () => testEnv.authenticatedContext('bob').storage();
const gSt = () => testEnv.unauthenticatedContext().storage();
const small = new Uint8Array(1024);
const png = { contentType: 'image/png' };
await check('alice uploads a post image', () => assertSucceeds(uploadBytes(ref(alSt(), 'posts/alice/p9/0.png'), small, png)));
await check('guest can read post images', () => assertSucceeds(getBytes(ref(gSt(), 'posts/alice/p9/0.png'))));
await check('bob cannot upload into alice\'s folder', () => assertFails(uploadBytes(ref(boSt(), 'posts/alice/p9/1.png'), small, png)));
await check('guest cannot upload', () => assertFails(uploadBytes(ref(gSt(), 'posts/alice/p9/2.png'), small, png)));
await check('non-image in posts/ is rejected', () => assertFails(uploadBytes(ref(alSt(), 'posts/alice/p9/x.txt'), small, { contentType: 'text/plain' })));
await check('21MB image is rejected', () => assertFails(uploadBytes(ref(alSt(), 'posts/alice/p9/big.png'), new Uint8Array(21 * 1024 * 1024), png)));
await check('commission reference image', () => assertSucceeds(uploadBytes(ref(boSt(), 'commissions/bob/c9/0.png'), small, png)));
await check('guest can read commission images', () => assertSucceeds(getBytes(ref(gSt(), 'commissions/bob/c9/0.png'))));
await check('commission folder rejects non-images', () => assertFails(uploadBytes(ref(boSt(), 'commissions/bob/c9/x.exe'), small, { contentType: 'application/octet-stream' })));
await check('alice cannot write into bob\'s commissions folder', () => assertFails(uploadBytes(ref(alSt(), 'commissions/bob/c9/1.png'), small, png)));
await check('consult image', () => assertSucceeds(uploadBytes(ref(boSt(), 'consults/bob/k9/orig.png'), small, png)));
await check('layer file to attachments/', () => assertSucceeds(uploadBytes(ref(alSt(), 'attachments/alice/p9/0_art.psd'), small, { contentType: 'application/octet-stream' })));
await check('bob cannot upload to alice\'s attachments', () => assertFails(uploadBytes(ref(boSt(), 'attachments/alice/p9/1_x.psd'), small, { contentType: 'application/octet-stream' })));
await check('bob cannot delete alice\'s image', () => assertFails(deleteObject(ref(boSt(), 'posts/alice/p9/0.png'))));
await check('alice can delete her image', () => assertSucceeds(deleteObject(ref(alSt(), 'posts/alice/p9/0.png'))));
await check('nothing outside the known folders is writable', () => assertFails(uploadBytes(ref(alSt(), 'random/alice/x.png'), small, png)));

console.log(`\n${passed} passed, ${failed} failed`);
await testEnv.cleanup();
process.exit(failed === 0 ? 0 : 1);
