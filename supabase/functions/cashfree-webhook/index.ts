// supabase/functions/cashfree-webhook/index.ts
// Deploy: supabase functions deploy cashfree-webhook
// Secrets zaroori: CASHFREE_SECRET_KEY, SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY
// (SUPABASE_URL aur SUPABASE_SERVICE_ROLE_KEY Supabase Edge Functions mein
// automatically available hote hain — alag se set karne ki zaroorat nahi)
//
// Cashfree har payment event par yeh URL POST karta hai. Signature verify
// karke hum orders table mein payment_status = 'paid' update karte hain —
// yehi asli source of truth hai, frontend redirect par bharosa nahi karte.

import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const CASHFREE_SECRET_KEY = Deno.env.get("CASHFREE_SECRET_KEY")!;
const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

const supabaseAdmin = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

async function hmacBase64(secret: string, message: string): Promise<string> {
  const key = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const sig = await crypto.subtle.sign("HMAC", key, new TextEncoder().encode(message));
  return btoa(String.fromCharCode(...new Uint8Array(sig)));
}

Deno.serve(async (req: Request) => {
  try {
    const rawBody = await req.text();
    const signature = req.headers.get("x-webhook-signature") ?? "";
    const timestamp = req.headers.get("x-webhook-timestamp") ?? "";

    const expectedSignature = await hmacBase64(CASHFREE_SECRET_KEY, timestamp + rawBody);

    if (expectedSignature !== signature) {
      console.warn("Webhook signature mismatch — ignoring");
      return new Response("Invalid signature", { status: 401 });
    }

    const event = JSON.parse(rawBody);
    const orderRef = event.data?.order?.order_id;
    const paymentStatus = event.data?.payment?.payment_status; // SUCCESS, FAILED, etc.

    if (orderRef && paymentStatus === "SUCCESS") {
      const { error } = await supabaseAdmin
        .from("orders")
        .update({ payment_status: "paid" })
        .eq("order_ref", orderRef);

      if (error) console.error("Supabase update error:", error);
      else console.log("Order marked paid:", orderRef);
    }

    return new Response("OK", { status: 200 });
  } catch (err) {
    console.error(err);
    return new Response("Bad request", { status: 400 });
  }
});
