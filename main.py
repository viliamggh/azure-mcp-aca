import asyncio
from fastmcp import FastMCP, Client

client = Client("http://127.0.0.1:8000/mcp/")

async def call_tool(a,b: int):
    async with client:
        result = await client.call_tool("add", {"a": a, "b": b})
        print(result)

asyncio.run(call_tool(4,2))
