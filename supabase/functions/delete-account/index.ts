// delete-account: stub for M0. Implemented in a later milestone (see docs/03-development-plan.md).
Deno.serve((_req: Request) =>
  new Response(JSON.stringify({ error: "not_implemented", function: "delete-account" }), {
    status: 501,
    headers: { "content-type": "application/json" },
  })
);
