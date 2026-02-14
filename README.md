<h1 align="center">
  <img src="https://raw.githubusercontent.com/johnbean393/Sidekick/refs/heads/main/Docs%20Images/appIcon.png" width = "200" height = "200">
  <br />
  MLAIX
</h1>

<p align="center">
<img alt="Downloads" src="https://img.shields.io/github/downloads/johnbean393/Sidekick/total?label=Downloads" height=22.5>
<img alt="License" src="https://img.shields.io/github/license/johnbean393/Sidekick?label=License" height=22.5>
</p>

Chat with a local LLM that can respond with information from your files, folders and websites on your Mac without installing any other software. All conversations happen offline, and your data stays secure. MLAIX is a <strong>local first</strong> application –– with a built in inference engine for local models, while accommodating OpenAI compatible APIs for additional model options.

![Screenshot](https://raw.githubusercontent.com/johnbean393/Sidekick/refs/heads/main/Docs%20Images/demoScreenshot.png)

## Example Use

Let’s say you're collecting evidence for a History paper about interactions between Aztecs and Spanish troops, and you’re looking for text about whether the Aztecs used captured Spanish weapons.

![Screenshot](https://raw.githubusercontent.com/johnbean393/Sidekick/refs/heads/main/Docs%20Images/Features/Experts/demoHistoryScreenshot.png)

Here, you can ask MLAIX, “Did the Aztecs use captured Spanish weapons?”, and it responds with direct quotes with page numbers and a brief analysis.

![Screenshot](https://raw.githubusercontent.com/johnbean393/Sidekick/refs/heads/main/Docs%20Images/Features/Experts/demoHistorySource.png)

To verify MLAIX’s answer, just click on the references displayed below MLAIX’s answer, and the academic paper referenced by MLAIX immediately opens in your viewer.

## Features

Read more about MLAIX's features and how to use them [here](https://johnbean393.github.io/Sidekick/).

### Resource Use

MLAIX accesses files, folders, and websites from your experts, which can be individually configured to contain resources related to specific areas of interest. Activating an expert allows MLAIX to fetch and reference materials as needed.

Because MLAIX uses RAG (Retrieval Augmented Generation), you can theoretically put unlimited resources into each expert, and MLAIX will still find information relevant to your request to aid its analysis.

For example, a student might create the experts `English Literature`, `Mathematics`, `Geography`, `Computer Science` and `Physics`. In the image below, he has activated the expert `Computer Science`.

![Screenshot](https://raw.githubusercontent.com/johnbean393/Sidekick/refs/heads/main/Docs%20Images/Features/Experts/demoExpertUse.png)

Users can also give MLAIX access to files just by dragging them into the input field.

![Screenshot](https://raw.githubusercontent.com/johnbean393/Sidekick/refs/heads/main/Docs%20Images/Features/Conversations/demoTemporaryResource.png)

MLAIX can even respond with the latest information using **web search**, speeding up research.

![Screenshot](https://raw.githubusercontent.com/johnbean393/Sidekick/refs/heads/main/Docs%20Images/Features/Web%20Search/webSearch.png)

### Bring Your Own API Key

In addition to its core local-first capabilities, MLAIX allows you to bring your own key for OpenAI compatible APIs. This allows you to tap into additional remote models while still preserving a primarily local-first workflow.

### Function Calling

MLAIX can call functions to boost the mathematical and logical capabilities of models, and to execute actions. Functions are called sequentially in a loop until a result is obtained.

For example, when asking MLAIX to calculate Q3 2025 financial metrics for Nvidia, it makes **27** tool calls, saves the CSV file and presents the results.

![Screenshot](https://raw.githubusercontent.com/johnbean393/Sidekick/refs/heads/main/Docs%20Images/Features/Function%20Calling/functionCallingFinancialMetrics.png)

When telling MLAIX to draft an invitation email for a birthday celebration to my friend Jean, MLAIX finds my birthday and Jean's email address from my contacts book, and creates a draft in my default email client. 

![Screenshot](https://raw.githubusercontent.com/johnbean393/Sidekick/refs/heads/main/Docs%20Images/Features/Function%20Calling/functionCallingDraftEmail.png)

This enables agents running fully locally. 

### Deep Research

Deep Research is a specific agent implemented in MLAIX to handle long horizon, multi-step research tasks.

![Screenshot](https://raw.githubusercontent.com/johnbean393/Sidekick/refs/heads/main/Docs%20Images/Features/Deep%20Research/deepResearchProgress.png)

Specify a research topic, and let MLAIX do the rest –– reading 50-80 webpages, and synthesizing information to prepare a research report.

![Screenshot](https://raw.githubusercontent.com/johnbean393/Sidekick/refs/heads/main/Docs%20Images/Features/Deep%20Research/deepResearchReport.png)

### Memory

MLAIX can now remember helpful information between conversations, making its responses more relevant and personalized. Whether you're typing, speaking, or generating images in MLAIX, it can recall details and preferences you’ve shared and use them to tailor its responses. The more you use it, the more useful it becomes, and you’ll start to notice improvements over time.

For example, I might tell MLAIX that I am a beginner in Python trying to create my own version of Tetris.

![Screenshot](https://raw.githubusercontent.com/johnbean393/Sidekick/refs/heads/main/Docs%20Images/Features/Memory/memoryRemember.png)

When I ask it about `pygame` alternatives, it makes recommendations based on my current project, Tetris.

![Screenshot](https://raw.githubusercontent.com/johnbean393/Sidekick/refs/heads/main/Docs%20Images/Features/Memory/memoryUse.png)

### Canvas

Create, edit and preview websites, code and other textual content using Canvas.

![Screenshot](https://raw.githubusercontent.com/johnbean393/Sidekick/refs/heads/main/Docs%20Images/Features/Canvas/canvasWebsite.png)

Select parts of the text, then prompt the chatbot to perform selective edits.

![Screenshot](https://raw.githubusercontent.com/johnbean393/Sidekick/refs/heads/main/Docs%20Images/Features/Canvas/canvasSelectiveEdit.png)

### Image Generation

MLAIX can generate images from text, allowing you to create visual aids for your work. 

There are no buttons, no switches to flick, no `Image Generation` mode. Instead, a built-in CoreML model **automatically identifies** image generation prompts, and generates an image when necessary.

![Screenshot](https://raw.githubusercontent.com/johnbean393/Sidekick/refs/heads/main/Docs%20Images/Features/Image%20Generation/imageGeneration.png)

Image generation is available on macOS 26 or above, and requires Apple Intelligence.

### Advanced Markdown Rendering

Markdown is rendered beautifully in MLAIX.

#### LaTeX

MLAIX offers native LaTeX rendering for mathematical equations.

![Screenshot](https://raw.githubusercontent.com/johnbean393/Sidekick/refs/heads/main/Docs%20Images/Features/Conversations/latexRendering1.png)

![Screenshot](https://raw.githubusercontent.com/johnbean393/Sidekick/refs/heads/main/Docs%20Images/Features/Conversations/latexRendering2.png)

#### Data Visualization

Visualizations are automatically generated for tables when appropriate, with a variety of charts available, including bar charts, line charts and pie charts.

![Screenshot](https://raw.githubusercontent.com/johnbean393/Sidekick/refs/heads/main/Docs%20Images/Features/Conversations/dataVisualization1.png)

![Screenshot](https://raw.githubusercontent.com/johnbean393/Sidekick/refs/heads/main/Docs%20Images/Features/Conversations/dataVisualization2.png)

Charts can be dragged and dropped into third party apps.

#### Code

Code is beautifully rendered with syntax highlighting, and can be exported or copied at the click of a button.

![Screenshot](https://raw.githubusercontent.com/johnbean393/Sidekick/refs/heads/main/Docs%20Images/Features/Conversations/codeExport.png)

### Toolbox

Use **Tools** in MLAIX to supercharge your workflow.

#### Inline Writing Assistant

Press `Command + Control + I` to access MLAIX's inline writing assistant. For example, use the `Answer Question` command to do your homework without leaving Microsoft Word!

![Screenshot](https://raw.githubusercontent.com/johnbean393/Sidekick/refs/heads/main/Docs%20Images/Features/Tools/Inline%20Writing%20Assistant/inlineWritingAssistantCommands.png)

Use the default keyboard shortcut `Tab` to accept suggestions for the next word, or `Shift + Tab` to accept all suggested words. View a demo [here](https://drive.google.com/file/d/1DDzdNHid7MwIDz4tgTpnqSA-fuBCajQA/preview).

![Screenshot](https://raw.githubusercontent.com/johnbean393/Sidekick/refs/heads/main/Docs%20Images/Features/Tools/Inline%20Writing%20Assistant/inlineWritingAssistantCompletions.png)

#### Detector

Use Detector to evaluate the AI percentage of text, and use provided suggestions to rewrite AI content.

![Screenshot](https://raw.githubusercontent.com/johnbean393/Sidekick/refs/heads/main/Docs%20Images/Features/Tools/Detector/detectorEvaluationResults.png)

#### Diagrammer

![Screenshot](https://raw.githubusercontent.com/johnbean393/Sidekick/refs/heads/main/Docs%20Images/Features/Tools/Diagrammer/diagrammerPrompt.png)

Diagrammer allows you to swiftly generate intricate relational diagrams all from a prompt. Take advantage of the integrated preview and editor for quick edits.

![Screenshot](https://raw.githubusercontent.com/johnbean393/Sidekick/refs/heads/main/Docs%20Images/Features/Tools/Diagrammer/diagrammerPreviewEditor2.png)

#### Slide Studio

![Screenshot](https://raw.githubusercontent.com/johnbean393/Sidekick/refs/heads/main/Docs%20Images/Features/Tools/Slide%20Studio/slideStudioPrompt.png)

Instead of making a PowerPoint, just write a prompt. Use AI to craft 10-minute presentations in just 5 minutes.

![Screenshot](https://raw.githubusercontent.com/johnbean393/Sidekick/refs/heads/main/Docs%20Images/Features/Tools/Slide%20Studio/slideStudioPreviewEditor.png)

Export to common formats like PDF and PowerPoint.

![Screenshot](https://raw.githubusercontent.com/johnbean393/Sidekick/refs/heads/main/Docs%20Images/Features/Tools/Slide%20Studio/slideStudioExport.png)

### Fast Generation

MLAIX uses `llama.cpp` as its inference backend, which is optimized to deliver lightning fast generation speeds on Apple Silicon. It also supports speculative decoding, which can further improve the generation speed.

![Screenshot](https://raw.githubusercontent.com/johnbean393/Sidekick/refs/heads/main/Docs%20Images/Features/Local%20Models/speculativeDecodingSupport.png)

Optionally, you can offload generation to speed up processing while extending the battery life of your MacBook.

![Screenshot](https://raw.githubusercontent.com/johnbean393/Sidekick/refs/heads/main/Docs%20Images/Features/Remote%20Models/remoteModelSettingsTop.png)

## Installation

**Requirements**
- A Mac with Apple Silicon
- RAM ≥ 8 GB

**Download and Setup**
- Follow the guide [here](https://johnbean393.github.io/Sidekick/Markdown/gettingStarted/).

## Goals

The main goal of MLAIX is to make open, local, private, and contextually aware AI applications accessible to the masses.

Read more about our mission [here](https://johnbean393.github.io/Sidekick/Markdown/About/mission/).

## Developer Setup

**Requirements**
- A Mac with Apple Silicon
- RAM ≥ 8 GB

### Developer Setup Instructions
1. Clone this repository.
1. Build and run with SwiftPM:
   - `swift build`
   - `swift run MLAIX` (macOS) — you must specify the product; `swift run` alone fails because the package has multiple executables.
   - `swift build --product MLAIXiOS` (iOS/iPadOS)
   - `swift build --product MLAIXtvos` (tvOS placeholder)
   - `swift test` (all tests -- 464 tests across 64 suites)
   - See [docs/TESTING.md](docs/TESTING.md) for test coverage and patterns

## Contributing

Contributions are very welcome. Let's make MLAIX simple and powerful.

## Contact

Contact this repository's owner at johnbean393@gmail.com, or file an issue.

## Credits

This project would not be possible without the hard work of:

- psugihara and contributors who built [FreeChat](https://github.com/psugihara/FreeChat), which this project took heavy inspiration from
- Georgi Gerganov for [llama.cpp](https://github.com/ggerganov/llama.cpp)
- Alibaba for training Qwen 2.5
- Meta for training Llama 3
- Google for training Gemma 3

## Star History

<a href="https://star-history.com/#johnbean393/Sidekick&Date">
 <picture>
   <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/svg?repos=johnbean393/Sidekick&type=Date&theme=dark" />
   <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/svg?repos=johnbean393/Sidekick&type=Date" />
   <img alt="Star History Chart" src="https://api.star-history.com/svg?repos=johnbean393/Sidekick&type=Date" />
 </picture>
</a>
