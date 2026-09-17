// Seed a deterministic API key from the ANYCRAWL_API_KEY environment variable so the deploy has a working,
// operator-known key (readable from the service's variables) instead of a random one printed to the logs. Uses
// AnyCrawl's own DB layer (@anycrawl/db). Idempotent: it inserts the key once and does nothing on later runs.
// Exits non-zero if the api_key table does not exist yet (migrations still running) so the entrypoint can retry.
import { getDB, schemas, eq } from "@anycrawl/db";

const key = process.env.ANYCRAWL_API_KEY;
if (!key) {
    console.log("[seed] ANYCRAWL_API_KEY is not set; skipping API key seed");
    process.exit(0);
}

const db = await getDB();
const [existing] = await db.select().from(schemas.apiKey).where(eq(schemas.apiKey.key, key)).limit(1);
if (existing) {
    console.log("[seed] API key already present; leaving it unchanged");
    process.exit(0);
}
await db.insert(schemas.apiKey).values({
    key,
    name: "railway",
    isActive: true,
    createdBy: -1,
    credits: 999999,
    createdAt: new Date(),
});
console.log("[seed] API key seeded from ANYCRAWL_API_KEY");
process.exit(0);
