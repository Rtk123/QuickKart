// supabase/functions/order-status/index.ts
// Deploy: supabase functions deploy order-status
// Secrets zaroori: CASHFREE_APP_ID, CASHFREE_SECRET_KEY, CASHFREE_ENV
//
// GET /functions/v1/order-status?order_id=QK123... -> Cashfree se live status

import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const CASHFREE_APP_ID = Deno.env.get("CASHFREE_APP_ID")!;
const CASHFREE_SECRET_KEY = Deno.env.get("CASHFREE_SECRET_KEY")!;
const CASHFREE_ENV = Deno.env.get("CASHFREE_ENV") ?? "sandbox";

const CASHFREE_BASE_URL =
  CASHFREE_ENV === "production"
    ? "https://api.cashfree.com/pg"
    : "https://sandbox.cashfree.com/pg";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const url = new URL(req.url);
  const orderId = url.searchParams.get("order_id");

  if (!orderId) {
    return new Response(JSON.stringify({ message: "order_id required" }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const cfRes = await fetch(`${CASHFREE_BASE_URL}/orders/${orderId}`, {
    headers: {
      "x-api-version": "2023-08-01",
      "x-client-id": CASHFREE_APP_ID,
      "x-client-secret": CASHFREE_SECRET_KEY,
    },
  });

  const data = await cfRes.json();
  return new Response(JSON.stringify(data), {
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
});
