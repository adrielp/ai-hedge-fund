# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

### Python Development
```bash
# Run the AI hedge fund
poetry run python src/main.py --ticker AAPL,MSFT,NVDA

# Run the backtester
poetry run python src/backtester.py --ticker AAPL,MSFT,NVDA

# Run with local LLMs (Ollama)
poetry run python src/main.py --ticker AAPL,MSFT,NVDA --ollama

# Run with reasoning output
poetry run python src/main.py --ticker AAPL,MSFT,NVDA --show-reasoning

# Run tests
poetry run pytest

# Format code
poetry run black src/

# Sort imports
poetry run isort src/

# Lint code
poetry run flake8 src/
```

### Frontend Development (app/frontend)
```bash
cd app/frontend

# Development server
npm run dev

# Build for production
npm run build

# Run linter
npm run lint

# Preview production build
npm run preview
```

### Backend API (app/backend)
```bash
cd app/backend

# Run FastAPI server
poetry run uvicorn main:app --reload

# API documentation available at:
# http://localhost:8000/docs
```

### Quick Start Scripts
```bash
# Full app setup and run (Mac/Linux)
./app/run.sh

# Full app setup and run (Windows)
app\run.bat

# Docker setup (from docker/ directory)
./run.sh build  # or run.bat build on Windows
```

## Architecture Overview

### Multi-Agent System Design
The AI hedge fund uses a **parallel-to-sequential pipeline** pattern powered by LangGraph:

```
Start → [Parallel Analyst Agents] → Risk Manager → Portfolio Manager → End
```

### Key Components

1. **Agent State Management** (`src/graph/state.py`)
   - Shared state dictionary with messages, data, and metadata
   - Custom merge functions for accumulating agent outputs
   - Enables data reuse across agents (e.g., cached API calls)

2. **Agent Types**
   - **15 Analyst Agents**: Each provides trading signals (bullish/bearish/neutral) with confidence scores
     - Investor personas (Warren Buffett, Charlie Munger, etc.) - LLM-powered analysis
     - Technical analysts (Fundamentals, Technicals, Sentiment, Valuation) - Rule-based or LLM
   - **Risk Manager**: Calculates position limits (max 20% per ticker)
   - **Portfolio Manager**: Makes final trading decisions based on all signals

3. **Workflow Orchestration** (`src/main.py`)
   - Uses LangGraph StateGraph for agent orchestration
   - Analysts run in parallel for efficiency
   - Sequential risk assessment and portfolio decisions ensure coherence

4. **Backend Integration** (`app/backend/`)
   - FastAPI with Server-Sent Events (SSE) for real-time progress
   - `/hedge-fund/run` endpoint executes the trading pipeline
   - Progress tracking broadcasts updates for each agent/ticker

5. **Data Flow**
   - Input: Tickers, date range, initial portfolio
   - Analysts fetch and analyze financial data independently
   - Risk manager enforces position limits
   - Portfolio manager synthesizes all signals into trades

### Agent Communication Pattern
Each agent:
- Reads from shared state (prices, portfolio, previous signals)
- Performs its analysis (fetching additional data if needed)
- Writes results back to shared state
- Example output: `{signal: "bullish", confidence: 80, reasoning: "Strong ROE..."}`

### Caching Strategy
- Financial data API calls are cached to reduce latency
- Cache improves performance when multiple agents need same data
- Located in `src/data/cache.py`

### Environment Configuration
Required API keys in `.env`:
- `OPENAI_API_KEY` / `GROQ_API_KEY` / `ANTHROPIC_API_KEY` / `DEEPSEEK_API_KEY` - For LLM agents
- `FINANCIAL_DATASETS_API_KEY` - For financial data (free for AAPL, GOOGL, MSFT, NVDA, TSLA)