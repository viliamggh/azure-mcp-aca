from fastmcp import FastMCP

# 1. Create the server
mcp = FastMCP(name="My First MCP Server")

# 2. Add a tool
@mcp.tool
def add(a: int, b: int) -> int:
    """Adds two integer numbers together."""
    return a + b

# 3. Add a static resource
@mcp.resource("resource://config")
def get_config() -> dict:
    """Provides the application's configuration."""
    return {"version": "1.0", "author": "MyTeam"}

# 4. Add a resource template for dynamic content
@mcp.resource("greetings://{name}")
def personalized_greeting(name: str) -> str:
    """Generates a personalized greeting for the given name."""
    return f"Hello, {name}! Welcome to the MCP server."

# 5. Add a health MCP resource for Azure probes
@mcp.resource("resource://health")
def health() -> dict:
    """Health check endpoint for Azure Container App probes."""
    return {"status": "ok"}


if __name__ == "__main__":
    # mcp.run(transport="http")
    import os 
    port = int(os.getenv('MCP_HTTP_PORT', '8000'))
    host = os.getenv('MCP_HTTP_HOST', '127.0.0.1')
    
    mcp.run(transport='http', port=port, host=host)

    
