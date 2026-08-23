// supabase/functions/create-order/index.ts
// Deploy: supabase functions deploy create-order
// Secrets zaroori: CASHFREE_APP_ID, CASHFREE_SECRET_KEY, CASHFREE_ENV, PROJECT_URL
//
// Yeh function Flutter app se call hota hai. Cashfree secret key sirf yahan
// (Supabase secrets mein) rehti hai — Flutter app ke andar kabhi nahi.

import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const CASHFREE_APP_ID = Deno.env.get("CASHFREE_APP_ID")!;
const CASHFREE_SECRET_KEY = Deno.env.get("CASHFREE_SECRET_KEY")!;
const CASHFREE_ENV = Deno.env.get("CASHFREE_ENV") ?? "sandbox";
const PROJECT_URL = Deno.env.get("PROJECT_URL")!; // e.g. https://kxcfqlciuzkydixjprks.supabase.co

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

  try {
    const { client_order_ref, amount, customer } = await req.json();

    if (!client_order_ref || !amount || amount <= 0) {
      return new Response(JSON.stringify({ message: "Invalid order data" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }
    if (!customer?.name || !customer?.phone || !customer?.email) {
      return new Response(JSON.stringify({ message: "Customer details incomplete" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const payload = {
      order_id: client_order_ref,
      order_amount: amount,
      order_currency: "INR",
      customer_details: {
        customer_id: "CUST" + customer.phone,
        customer_name: customer.name,
        customer_email: customer.email,
        customer_phone: customer.phone,
      },
      order_meta: {
        return_url: `${PROJECT_URL}/functions/v1/order-status?order_id={order_id}`,
        notify_url: `${PROJECT_URL}/functions/v1/cashfree-webhook`,
      },
    };

    const cfRes = await fetch(`${CASHFREE_BASE_URL}/orders`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-api-version": "2023-08-01",
        "x-client-id": CASHFREE_APP_ID,
        "x-client-secret": CASHFREE_SECRET_KEY,
      },
      body: JSON.stringify(payload),
    });

    const cfData = await cfRes.json();

    if (!cfRes.ok) {
      console.error("Cashfree error:", cfData);
      return new Response(
        JSON.stringify({ message: cfData.message ?? "Cashfree order create failed" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    return new Response(
      JSON.stringify({
        order_id: client_order_ref,
        payment_session_id: cfData.payment_session_id,
        mode: CASHFREE_ENV === "production" ? "production" : "sandbox",
      }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  } catch (err) {
    console.error(err);
    return new Response(JSON.stringify({ message: "Server error" }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
