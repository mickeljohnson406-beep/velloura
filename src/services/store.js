import { addDoc, collection, getDocs, orderBy, query, serverTimestamp, where } from 'firebase/firestore';
import { db, firebaseConfigured } from '../firebase';

export async function loadActiveProducts() {
  if (!firebaseConfigured || !db) return null;
  const q = query(collection(db, 'products'), where('active', '==', true), orderBy('name'));
  const snap = await getDocs(q);
  return snap.docs.map(d => ({ id: d.id, ...d.data() }));
}

export async function createOrder(order) {
  if (!firebaseConfigured || !db) throw new Error('Firebase is not configured');
  const payload = {
    ...order,
    status: 'pending',
    paymentStatus: 'unpaid',
    createdAt: serverTimestamp(),
  };
  const ref = await addDoc(collection(db, 'orders'), payload);
  return ref.id;
}
