import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { getFirestore, FieldValue, GeoPoint } from 'firebase-admin/firestore';

const firestore = getFirestore();

interface PlaceOrderItem {
  productId: string;
  quantity: number;
}

interface PlaceOrderRequest {
  shopId: string;
  items: PlaceOrderItem[];
  deliveryType: 'delivery' | 'pickup';
  dropoffGeopoint: { lat: number; lng: number };
  dropoffAddressLabel: string;
  paymentMethod: 'cash' | 'wallet' | 'gateway';
  customerNote?: string;
}

/**
 * Haversine distance in kilometers between two GeoPoints.
 * Mirrors the client-side Geolocator.distanceBetween calculation (Phase 3.3)
 * so the delivery fee can never be tampered with by a modified client
 * claiming a shorter distance — this is the server-authoritative source.
 */
function haversineKm(a: GeoPoint, b: { lat: number; lng: number }): number {
  const R = 6371; // Earth radius in km
  const dLat = ((b.lat - a.latitude) * Math.PI) / 180;
  const dLng = ((b.lng - a.longitude) * Math.PI) / 180;
  const lat1 = (a.latitude * Math.PI) / 180;
  const lat2 = (b.lat * Math.PI) / 180;

  const h =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(lat1) * Math.cos(lat2) * Math.sin(dLng / 2) ** 2;
  const c = 2 * Math.atan2(Math.sqrt(h), Math.sqrt(1 - h));
  return R * c;
}

/** Human-friendly order number, e.g. "VM-20260622-A1B2". */
function generateOrderNumber(): string {
  const datePart = new Date().toISOString().slice(0, 10).replace(/-/g, '');
  const randomPart = Math.random().toString(36).slice(2, 6).toUpperCase();
  return `VM-${datePart}-${randomPart}`;
}

/**
 * Callable Cloud Function — the ONLY way orders are created (see
 * firestore.rules: `allow create: if false` on /orders). Runs with Admin
 * SDK privileges, validates price/stock against live product documents, and
 * atomically decrements stock within the same transaction as the order
 * write. See Phase 3.2 / Phase 4 of the blueprint for the full rationale.
 */
export const placeOrder = onCall<PlaceOrderRequest>(async (request) => {
  const { auth, data } = request;
  if (!auth) {
    throw new HttpsError('unauthenticated', 'يجب تسجيل الدخول');
  }
  if (!data.shopId || !Array.isArray(data.items) || data.items.length === 0) {
    throw new HttpsError('invalid-argument', 'بيانات الطلب غير مكتملة');
  }

  return firestore.runTransaction(async (tx) => {
    const productRefs = data.items.map((i) =>
      firestore.doc(`shops/${data.shopId}/products/${i.productId}`),
    );
    const productSnaps = await Promise.all(productRefs.map((r) => tx.get(r)));

    let subtotal = 0;
    const snapshotItems: Array<{
      productId: string;
      productName: string;
      imageUrl: string | null;
      unitPrice: number;
      quantity: number;
      lineTotal: number;
    }> = [];

    for (let i = 0; i < productSnaps.length; i++) {
      const snap = productSnaps[i];
      if (!snap.exists) {
        throw new HttpsError('not-found', 'منتج غير موجود');
      }
      const product = snap.data()!;
      const requestedQty = data.items[i].quantity;

      if (product.stockQuantity < requestedQty) {
        throw new HttpsError('failed-precondition', `الكمية غير متوفرة: ${product.name}`);
      }

      // Server-authoritative price — never trust a client-submitted price.
      const unitPrice: number = product.discountPrice ?? product.price;
      subtotal += unitPrice * requestedQty;

      snapshotItems.push({
        productId: snap.id,
        productName: product.name,
        imageUrl: product.imageUrls?.[0] ?? null,
        unitPrice,
        quantity: requestedQty,
        lineTotal: unitPrice * requestedQty,
      });

      // Decrement stock atomically within the same transaction as order creation.
      tx.update(productRefs[i], {
        stockQuantity: product.stockQuantity - requestedQty,
        isInStock: product.stockQuantity - requestedQty > 0,
      });
    }

    const shopSnap = await tx.get(firestore.doc(`shops/${data.shopId}`));
    if (!shopSnap.exists) {
      throw new HttpsError('not-found', 'المتجر غير موجود');
    }
    const shop = shopSnap.data()!;
    if (!shop.isApproved || !shop.isActive) {
      throw new HttpsError('failed-precondition', 'هذا المتجر غير متاح حالياً');
    }

    const deliveryFee = data.deliveryType === 'delivery' ? shop.baseDeliveryFee : 0;
    const totalAmount = subtotal + deliveryFee;

    const orderRef = firestore.collection('orders').doc();
    tx.set(orderRef, {
      orderId: orderRef.id,
      orderNumber: generateOrderNumber(),
      customerId: auth.uid,
      customerName: auth.token.name ?? '',
      customerPhone: auth.token.phone_number ?? '',
      shopId: data.shopId,
      shopName: shop.shopName,
      vendorId: shop.ownerId,
      driverId: null,
      driverName: null,
      items: snapshotItems,
      pricing: {
        subtotal,
        deliveryFee,
        serviceFee: 0,
        discountAmount: 0,
        taxAmount: 0,
        totalAmount,
      },
      payment: {
        method: data.paymentMethod,
        status: 'pending',
        gatewayReference: null,
        paidAt: null,
      },
      delivery: {
        type: data.deliveryType,
        dropoffGeopoint: new GeoPoint(data.dropoffGeopoint.lat, data.dropoffGeopoint.lng),
        dropoffAddressLabel: data.dropoffAddressLabel,
        distanceKm: shop.location?.geopoint
          ? haversineKm(shop.location.geopoint, data.dropoffGeopoint)
          : null,
        estimatedMinutes: null,
      },
      status: 'pending',
      statusHistory: [
        {
          status: 'pending',
          timestamp: FieldValue.serverTimestamp(),
          changedBy: auth.uid,
          note: null,
        },
      ],
      cancellation: null,
      customerNote: data.customerNote ?? '',
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
      acceptedAt: null,
      deliveredAt: null,
    });

    return { orderId: orderRef.id };
  });
});
