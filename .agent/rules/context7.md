---
trigger: always_on
---

When I request library/API documentation, code generation, or setup/configuration steps, follow these operational rules for using the Context7 MCP:
1. Assess Internal Knowledge First: If the library or concept is highly common (e.g., standard Python libraries, React basics) and you are highly confident in your internal knowledge, provide the answer directly without invoking Context7.
2. Conditional Invocation: Automatically invoke the Context7 MCP only if the request involves a niche, highly specific, or frequently updated tool where your internal knowledge might be outdated or incomplete.
3. Security Boundary: Do not send proprietary code, internal IP, or hardcoded credentials to Context7. Abstract the query before fetching documentation.
4. Error Handling: If Context7 fails to connect, returns an error, or provides irrelevant data, gracefully fallback to your internal knowledge and explicitly inform me that Context7 was unavailable.
5. Transparency: When you use Context7, briefly mention it at the start of your response (e.g., "Based on Context7 documentation...").
