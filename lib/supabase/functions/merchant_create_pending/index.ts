// Supabase Edge Function: merchant_create_pending
// Creates/updates a pending merchant record right after sign-up.
// This is intentionally public (verify_jwt should be set to false) because
// when email confirmations are enabled, signUp() returns no session.

const CORS_HEADERS: Record<string, string> = {
  "access-control-allow-origin": "*",
  "access-control-allow-headers": "authorization, x-client-info, apikey, content-type",
  "access-control-allow-methods": "POST, OPTIONS",
  "access-control-max-age": "86400",
};

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS_HEADERS });

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    if (!supabaseUrl || !serviceRoleKey) {
      return new Response(JSON.stringify({ success: false, error: "Server not configured" }), {
        status: 500,
        headers: { ...CORS_HEADERS, "content-type": "application/json" },
      });
    }

    const admin = createClient(supabaseUrl, serviceRoleKey, {
      auth: { persistSession: false, autoRefreshToken: false },
    });

    const body = await req.json().catch(() => null);
    if (!body || typeof body !== "object") {
      return new Response(JSON.stringify({ success: false, error: "Invalid JSON body" }), {
        status: 400,
        headers: { ...CORS_HEADERS, "content-type": "application/json" },
      });
    }

    const profileId = typeof body.profile_id === "string" ? body.profile_id : "";
    const businessName = typeof body.business_name === "string" ? body.business_name.trim() : "";
    const ownerFirstName = typeof body.owner_first_name === "string" ? body.owner_first_name.trim() : "";
    const ownerLastName = typeof body.owner_last_name === "string" ? body.owner_last_name.trim() : "";
    const businessEmail = typeof body.business_email === "string" ? body.business_email.trim().toLowerCase() : "";
    const businessPhone = typeof body.business_phone === "string" ? body.business_phone.trim() : "";
    const categories = Array.isArray(body.categories)
      ? body.categories.filter((x: unknown): x is string => typeof x === "string")
      : [];
    const addressLine1 = typeof body.address_line1 === "string" ? body.address_line1.trim() : "";
    const addressLine2 = typeof body.address_line2 === "string" ? body.address_line2.trim() : null;
    const city = typeof body.city === "string" ? body.city.trim() : "";
    const postalCode = typeof body.postal_code === "string" ? body.postal_code.trim() : "";
    const countryName = typeof body.country_name === "string" ? body.country_name.trim() : "";

    if (!profileId || !businessName || !ownerFirstName || !ownerLastName || !businessEmail) {
      return new Response(
        JSON.stringify({ success: false, error: "Missing required fields" }),
        { status: 400, headers: { ...CORS_HEADERS, "content-type": "application/json" } },
      );
    }

    // Ensure a minimal profile row exists (some setups rely on triggers; this is defensive).
    // If your DB trigger already creates profiles, this upsert is harmless.
    const { error: profileErr } = await admin.from("profiles").upsert(
      {
        id: profileId,
        email: businessEmail,
        full_name: `${ownerFirstName} ${ownerLastName}`.trim(),
        phone: businessPhone,
        role: "merchant",
      },
      { onConflict: "id" },
    );
    if (profileErr) {
      return new Response(JSON.stringify({ success: false, error: profileErr.message }), {
        status: 500,
        headers: { ...CORS_HEADERS, "content-type": "application/json" },
      });
    }

    const now = new Date().toISOString();
    const merchantRow: Record<string, unknown> = {
      profile_id: profileId,
      business_name: businessName,
      owner_first_name: ownerFirstName,
      owner_last_name: ownerLastName,
      business_email: businessEmail,
      business_phone: businessPhone,
      categories,
      address_line1: addressLine1,
      address_line2: addressLine2,
      city,
      postal_code: postalCode,
      country_name: countryName,
      status: "pending",
      profile_completed: false,
      updated_at: now,
    };

    // Create or update (in case the same user retries).
    const { data, error } = await admin
      .from("merchants")
      .upsert(merchantRow, { onConflict: "profile_id" })
      .select("profile_id")
      .single();

    if (error) {
      return new Response(JSON.stringify({ success: false, error: error.message }), {
        status: 500,
        headers: { ...CORS_HEADERS, "content-type": "application/json" },
      });
    }

    return new Response(JSON.stringify({ success: true, profile_id: data?.profile_id ?? profileId }), {
      status: 200,
      headers: { ...CORS_HEADERS, "content-type": "application/json" },
    });
  } catch (e) {
    return new Response(JSON.stringify({ success: false, error: String(e) }), {
      status: 500,
      headers: { ...CORS_HEADERS, "content-type": "application/json" },
    });
  }
});
