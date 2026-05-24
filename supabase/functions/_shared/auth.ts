import { createClient } from "npm:@supabase/supabase-js@2";

export type AuthResult =
  | { userId: string; token: string; reason: "ok" }
  | { userId: null; token: null; reason: string };

export function parseBearerToken(authHeader: string | null): string | null {
  if (!authHeader) return null;
  const match = authHeader.match(/^Bearer\s+(.+)$/i);
  const token = match?.[1]?.trim() ?? "";
  return token.length > 0 ? token : null;
}

export async function authenticateUser(
  authHeader: string | null,
  supabaseUrl: string,
  supabaseAnonKey: string,
): Promise<AuthResult> {
  const token = parseBearerToken(authHeader);
  if (!token) {
    return { userId: null, token: null, reason: "missing_bearer_token" };
  }

  if (!supabaseUrl || !supabaseAnonKey) {
    return { userId: null, token: null, reason: "missing_auth_env" };
  }

  const supabase = createClient<any>(supabaseUrl, supabaseAnonKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  const { data, error } = await supabase.auth.getUser(token);
  if (error || !data.user) {
    return { userId: null, token: null, reason: "invalid_auth_token" };
  }

  return { userId: data.user.id, token, reason: "ok" };
}
