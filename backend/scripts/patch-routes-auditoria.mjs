import fs from "fs";
import path from "path";

const routesDir = path.join(import.meta.dirname, "../src/routes");

for (const file of fs.readdirSync(routesDir).filter((f) => f.endsWith(".ts"))) {
  let c = fs.readFileSync(path.join(routesDir, file), "utf8");
  const original = c;

  if (
    !c.includes(".map(map") &&
    !c.match(/reply\.send\(map\w+/) &&
    !c.includes("items.map(map")
  ) {
    continue;
  }

  if (!c.includes("resposta-api")) {
    const firstImportEnd = c.indexOf("\n", c.indexOf("import "));
    const insertAt = c.indexOf("\n", firstImportEnd) + 1;
    c =
      c.slice(0, insertAt) +
      'import { replyMapped, replyMappedList } from "../lib/resposta-api.js";\n' +
      c.slice(insertAt);
  }

  c = c.replace(
    /return reply\.send\(items\.map\((map\w+)\)\);/g,
    "return replyMappedList(reply, items, $1);",
  );
  c = c.replace(
    /return reply\.send\((map\w+)\((\w+)\)\);/g,
    "return replyMapped(reply, $2, $1);",
  );
  c = c.replace(
    /return reply\.status\(201\)\.send\((map\w+)\((\w+)\)\);/g,
    "return replyMapped(reply, $2, $1, 201);",
  );

  if (c !== original) {
    fs.writeFileSync(path.join(routesDir, file), c);
    console.log("patched", file);
  }
}
