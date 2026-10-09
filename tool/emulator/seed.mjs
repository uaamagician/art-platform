// Seeds the local Firebase emulators with realistic data for UI integration tests.
process.env.FIRESTORE_EMULATOR_HOST = '127.0.0.1:8085';
process.env.FIREBASE_AUTH_EMULATOR_HOST = '127.0.0.1:9099';
process.env.FIREBASE_STORAGE_EMULATOR_HOST = '127.0.0.1:9199';

import zlib from 'node:zlib';
import { initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore, FieldValue, Timestamp } from 'firebase-admin/firestore';
import { getStorage } from 'firebase-admin/storage';

const BUCKET = 'art-platform-a2f95.firebasestorage.app';
const HOST = '10.0.2.2:9199'; // how the Android emulator reaches the host's Storage emulator

const app = initializeApp({ projectId: 'art-platform-a2f95', storageBucket: BUCKET });
const db = getFirestore(app, 'artdf');
const auth = getAuth(app);
const bucket = getStorage(app).bucket();

// ---- tiny PNG encoder (gradient) ------------------------------------------
const crcTable = Array.from({ length: 256 }, (_, n) => {
  let c = n;
  for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1;
  return c >>> 0;
});
const crc32 = (buf) => {
  let c = 0xffffffff;
  for (const b of buf) c = crcTable[(c ^ b) & 0xff] ^ (c >>> 8);
  return (c ^ 0xffffffff) >>> 0;
};
const chunk = (type, data) => {
  const len = Buffer.alloc(4);
  len.writeUInt32BE(data.length);
  const body = Buffer.concat([Buffer.from(type), data]);
  const crc = Buffer.alloc(4);
  crc.writeUInt32BE(crc32(body));
  return Buffer.concat([len, body, crc]);
};
function png(w, h, hue) {
  const row = w * 3 + 1;
  const raw = Buffer.alloc(row * h);
  for (let y = 0; y < h; y++) {
    raw[y * row] = 0;
    for (let x = 0; x < w; x++) {
      const t = (x / w + y / h) / 2;
      const o = y * row + 1 + x * 3;
      raw[o] = Math.round(60 + 180 * t * (hue === 0 ? 1 : 0.4));
      raw[o + 1] = Math.round(90 + 140 * (1 - t) * (hue === 1 ? 1 : 0.5));
      raw[o + 2] = Math.round(100 + 130 * Math.abs(0.5 - t) * 2 * (hue === 2 ? 1 : 0.6));
    }
  }
  const ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(w, 0);
  ihdr.writeUInt32BE(h, 4);
  ihdr[8] = 8; ihdr[9] = 2;
  return Buffer.concat([
    Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
    chunk('IHDR', ihdr),
    chunk('IDAT', zlib.deflateSync(raw)),
    chunk('IEND', Buffer.alloc(0)),
  ]);
}
async function upload(path, hue, w = 600, h = 800) {
  const token = `seed-${Math.random().toString(36).slice(2)}`;
  await bucket.file(path).save(png(w, h, hue), {
    contentType: 'image/png',
    metadata: { metadata: { firebaseStorageDownloadTokens: token } },
  });
  return `http://${HOST}/v0/b/${BUCKET}/o/${encodeURIComponent(path)}?alt=media&token=${token}`;
}

const minutesAgo = (m) => Timestamp.fromMillis(Date.now() - m * 60000);

// ---- accounts ---------------------------------------------------------------
const people = {
  alice: { name: 'Alice 林', bio: '' },
  bob: { name: 'Bob 陳', bio: '素描與水彩，每天一張' },
  carol: { name: 'Carol 王', bio: '角色設計 / 接稿中' },
};
for (const [uid, p] of Object.entries(people)) {
  await auth.createUser({
    uid, email: `${uid}@test.com`, password: 'password', displayName: p.name,
  });
  await db.doc(`users/${uid}`).set({
    displayName: p.name, email: `${uid}@test.com`, showNsfw: false, showAi: false, createdAt: FieldValue.serverTimestamp(),
  });
}
// alice deliberately has no profile document: the app must create it on first sign-in
for (const uid of ['bob', 'carol']) {
  await db.doc(`profiles/${uid}`).set({
    displayName: people[uid].name, photoUrl: '', bio: people[uid].bio,
    postCount: uid === 'bob' ? 4 : 2, commentCount: 0, likedCount: 0, createdAt: FieldValue.serverTimestamp(),
  });
}

// ---- reference data ---------------------------------------------------------
const categories = ['傳統手繪', '顏料繪畫', '數位繪圖', '版畫印刷', '特殊技法'];
for (const [i, name] of categories.entries()) await db.collection('categories').doc(`cat${i}`).set({ name, order: i });
for (const t of ['水彩畫', '油畫', '鉛筆素描', '電繪', '木刻版畫', '壓克力畫']) {
  await db.doc(`tags/${t}`).set({ name: t, usageCount: 0, type: 'medium' });
}

// ---- posts ------------------------------------------------------------------
async function post(id, uid, o) {
  const urls = [];
  for (let i = 0; i < (o.images ?? 1); i++) urls.push(await upload(`posts/${uid}/${id}/${i}.png`, o.hue ?? 0));
  await db.doc(`posts/${id}`).set({
    userId: uid, userName: people[uid].name, userPhotoUrl: '', userBio: people[uid].bio,
    title: o.title, description: o.description ?? '', imageUrl: urls[0], imageUrls: urls, attachments: [],
    category: o.category ?? '傳統手繪', tags: o.tags ?? [], isNsfw: o.nsfw ?? false, isAiGenerated: o.ai ?? false,
    likesCount: o.likes ?? 0, commentsCount: 0, aspectRatio: 0.75, createdAt: minutesAgo(o.age ?? 10),
  });
}
await post('p1', 'bob', { title: '窗邊的靜物', description: '用 2B 鉛筆畫了一個下午', tags: ['鉛筆素描', '靜物'], age: 5, hue: 0, likes: 3 });
await post('p2', 'bob', { title: '雨後街景', tags: ['水彩畫', '街景'], age: 30, hue: 1, images: 3, category: '顏料繪畫' });
await post('p3', 'bob', { title: 'NSFW 習作', tags: ['人體'], nsfw: true, age: 60, hue: 2 });
await post('p4', 'bob', { title: 'AI 試驗圖', tags: ['ai'], ai: true, age: 90, hue: 1 });
await post('p5', 'carol', { title: '原創角色設定', tags: ['電繪', '角色設計'], category: '數位繪圖', age: 15, hue: 2, likes: 1 });
await post('p6', 'carol', { title: '木刻小品', tags: ['木刻版畫'], category: '版畫印刷', age: 200, hue: 0 });

// ---- commissions ------------------------------------------------------------
const commission = async (id, uid, o) => db.doc(`commissions/${id}`).set({
  userId: uid, userName: people[uid].name, userPhotoUrl: '', type: o.type, title: o.title,
  description: o.description ?? '', category: o.category ?? '', tags: o.tags ?? [], budgetText: o.budget ?? '',
  contact: o.contact ?? 'IG: @seed', imageUrls: [], isNsfw: false, status: o.status ?? 'open',
  reportCount: o.reports ?? 0, createdAt: minutesAgo(o.age ?? 20),
  ...(o.deadlineDays ? { deadline: Timestamp.fromMillis(Date.now() + o.deadlineDays * 86400000) } : {}),
});
await commission('m1', 'carol', { type: 'request', title: '徵 VTuber 立繪', budget: 'NT$3000 起', deadlineDays: 20, tags: ['立繪'], description: '需要全身立繪與表情差分', age: 10 });
await commission('m2', 'bob', { type: 'offer', title: '頭像接單中', budget: 'NT$800', tags: ['頭像'], age: 40 });
await commission('m3', 'carol', { type: 'request', title: '可疑的高價委託', reports: 3, age: 50 });

// ---- consult ----------------------------------------------------------------
await db.doc('consults/k1').set({
  userId: 'bob', userName: people.bob.name, userPhotoUrl: '', title: '手的比例總是怪怪的', description: '請問手掌和手指的長度怎麼抓？',
  imageUrl: await upload('consults/bob/k1/original.png', 1), floorsCount: 1, createdAt: minutesAgo(45),
});
await db.doc('consults/k1/floors/f1').set({
  floor: 1, userId: 'carol', userName: people.carol.name, userPhotoUrl: '', text: '手掌長度大約等於中指長度，可以先用方塊概括。',
  imageUrl: '', deleted: false, createdAt: minutesAgo(30),
});

// ---- group ------------------------------------------------------------------
await db.doc('groups/g1').set({
  name: '速寫小聚', description: '每週一起畫速寫', ownerId: 'bob', memberIds: ['bob', 'carol'], locked: false,
  lastMessage: '歡迎新朋友', lastMessageAt: minutesAgo(15), createdAt: minutesAgo(1000),
});
await db.collection('groups/g1/messages').add({
  userId: 'bob', userName: people.bob.name, userPhotoUrl: '', text: '歡迎新朋友', createdAt: minutesAgo(15),
});
await db.collection('groups/g1/strokes').add({
  userId: 'bob', color: 0xFFC9402F, width: 6, points: [0.2, 0.2, 0.5, 0.4, 0.8, 0.3], createdAt: minutesAgo(14),
});

console.log('seeded');
