# BC Copilot Eval Toolkit
The BC Copilot Eval Toolkit lets developers write and run automated evals for copilot features. The toolkit supports running data driven evals and the ability to get the output generated from the evals.

## Running AI evals in BC Copilot Eval Toolkit

### Prerequisite
1. The BC Copilot Eval Toolkit is installed
1. Datasets and evals are written (see [Writing data-driven AI evals](#writing-data-driven-ai-evals))

### Setup
1. In _Business Central_, open the _AI Eval Suite_ page
1. Upload the required datasets for the evals
1. Create an eval suite
1. In the eval suite, define a line for each codeunit

### Execute
1. Run the AI Eval Suite from the header, or one line at a time
1. The eval method will be executed for each dataset line
    1. If the eval evaluates in AL, it will either fail or succeed based on the condition
    1. If the test output is set, it must be generated for all the evals which needs to be evaluated externally
1. Results are logged in AI 'Log Entries'

### Inspect the results
1. Open _Log Entries_ to result of each execution
1. Download the test output which generates the `.jsonl` file or export the logs to Excel
1. You can also use the API (page 149038 "AIT Log Entry API") to get the result for a suite
1. Open AL Test Tool and switch to the created eval suite to execute each eval manually


## Writing data-driven AI evals

### Defining test codeunit
A data-driven AI eval is defined like any normal AL test, except that it:
1. Is executed through the BC Copilot Eval Toolkit
2. Utilizes the `AIT Test Context` codeunit to get input for the eval
3. Optionally, sets the output using the `AIT Test Context` codeunit

See the `AIT Test Context` for the full API.

#### Example
An example eval for an AI feature that returns an integer.

```
    [Test]
    procedure TestCopilotFeature()
    var
        AITestContext: Codeunit "AIT Test Context";
        Question: Text;
        Output: Integer;
        ExpectedOutput: Integer;
    begin
        // [Scenario] AI Eval

        // Call the LLM to get an output
        Output := CopilotFeature.CallLLM(Question);

        // Get the expected output from the dataset
        ExpectedOutput := AITestContext.GetExpectedData().ValueAsInteger();

        // Assert the result
        Assert.AreEqual(ExpectedOutput, Output, '');
    end;
```
In this example
1. This eval procedure will be called with each input from the dataset
1. We get the `question` and `expected_data` from the input dataset using `AITestContext.GetQuestion()` and `AITestContext.GetExpectedData()` respectively
1. Alternatively, we could use `AITestContext.GetInput()` and get the line as `json` 


## Writing language-first data-driven AI evals (recommended)

AL supports data-driven testing as a first-class construct via the `[TestDataSource]` attribute, where the
**platform** (not the toolkit) drives the per-case fan-out. The AI Test Toolkit ships a **shared** data source
and context so any app can adopt this with no per-app framework code.

### Defining the test codeunit
- Annotate each eval method with `[TestDataSource(Codeunit::"AIT Test Data Source", '<dataset>')]`.
- The method takes a single parameter of type `interface "AIT Test Case Context"` (which extends the platform
  `ITestContext`) and exposes the same input/output surface as the classic `AIT Test Context` codeunit.
- Register the toolkit's per-case handler with `TestHandlers = "AIT Test Handler"`. Under the **platform** test
  runner (no Eval Suite) this handler brackets each case — resetting per-case accuracy/turns/token accounting and
  writing one `AIT Log Entry` per case — the work the classic runner does through its event subscribers.

```
codeunit 50100 "My Copilot Eval"
{
    Subtype = Test;
    TestHandlers = "AIT Test Handler";

    [TestDataSource(Codeunit::"AIT Test Data Source", 'MY-DATASET')]
    procedure TestCopilotFeature(context: interface "AIT Test Case Context")
    var
        Output: Integer;
    begin
        Output := CopilotFeature.CallLLM(context.GetQuery().ValueAsText());
        context.SetTestOutput(Format(Output));
        Assert.AreEqual(context.GetExpectedData().ValueAsInteger(), Output, '');
    end;
}
```

### Datasets and the shared data source
- Datasets are authored as `.jsonl`/`.yaml` and imported into the shared `Test Input` tables (via the Eval Suite
  / dataset import), exactly as for classic evals; each row's `name` becomes the case identifier.
- The shared `"AIT Test Data Source"` provider resolves the dataset and returns one case per row:
  - under an **Eval Suite**, it uses the dataset configured on the current suite line (so the same method can run
    against multiple datasets across lines);
  - **standalone**, it uses the `'<dataset>'` identifier from the attribute (a Test Input Group code or name).

### Running under an Eval Suite (coexistence with classic evals)
- The toolkit **auto-detects** language-first codeunits (via `CodeUnit Metadata."Has Test Data Source"`) and adds
  their methods once — no per-row expansion — so the platform drives the per-case fan-out and there is no double
  execution. On a platform that does not expose that field yet, set **Language-First = true** on the eval line as
  an explicit override.
- A codeunit must be **either** classic data-driven **or** language-first; do not mix both styles in the same
  codeunit (plain `[Test]` methods may coexist with either).

## Migrating a classic eval to language-first

Converting a classic AIT eval codeunit to the `[TestDataSource]` construct is a small, mechanical change per
codeunit:

1. **Attribute:** `[Test]` → `[TestDataSource(Codeunit::"AIT Test Data Source", '<default dataset>')]`. The
   `'<default dataset>'` (a `Test Input Group` code/name) is used when the test runs standalone; under an Eval
   Suite the dataset configured on the suite line takes precedence, so one method still runs against multiple
   datasets across lines.
2. **Signature:** add a single parameter of the shared context interface —
   `procedure MyEval(context: interface "AIT Test Case Context")`.
3. **Body:** remove the `AITestContext: Codeunit "AIT Test Context"` variable and call the same methods on the
   `context` parameter (`GetInput`, `GetQuery`, `GetExpectedData`, `SetTestOutput`, `SetAccuracy`, `NextTurn`, …) —
   the names/signatures are identical.
4. **Handler:** add `TestHandlers = "AIT Test Handler"` to the codeunit so per-case logging/metrics engage when the
   eval runs on the platform test runner (outside an Eval Suite).
5. Leave everything else unchanged — `Subtype = Test`, `TestType = AITest`, `TestPermissions`, `SingleInstance`,
   and the eval logic.

```AL
// Before
[Test]
procedure GenerateChatCompletion()
var
    AITestContext: Codeunit "AIT Test Context";
begin
    Question := AITestContext.GetInput().Element('query').Element('question').ValueAsText();
    // ...
    AITestContext.SetTestOutput(Context, Question, Answer);
end;

// After  (drop the "AIT Test Context" var; receive the context as a parameter;
//          add TestHandlers = "AIT Test Handler" to the codeunit)
[TestDataSource(Codeunit::"AIT Test Data Source", 'AI-SDK-E2E-GPT41.YAML')]
procedure GenerateChatCompletion(AITestContext: interface "AIT Test Case Context")
begin
    Question := AITestContext.GetInput().Element('query').Element('question').ValueAsText();
    // ...
    AITestContext.SetTestOutput(Context, Question, Answer);
end;
```

**Rules & notes**
- **Migrate the whole codeunit** — a codeunit is either classic or language-first, never both (plain `[Test]`
  methods may coexist).
- **Nothing else changes** — datasets (`.jsonl`/`.yaml`), the Eval Suite, logging, run history and external
  (BCEval) output are all unchanged; the shared `AIT Test Data Source` provider resolves the dataset and the
  platform drives the fan-out.
- **Multi-turn** evals: `NextTurn()` / `GetCurrentTurn()` are on the interface — migrate the same way.
- **Harms / adversarial** evals (case content generated at run time, e.g. via `Adversarial Simulation`) need a
  data source that yields **stable, deterministic** case identifiers, so they require a small **custom
  `ITestDataSource` provider** rather than the plain shared one — not just the mechanical edit above.
- **Custom per-case data:** define your own interface `extends "AIT Test Case Context"` (or `ITestContext`) plus a
  custom `ITestDataSource` provider if a test needs extra per-case accessors.

**Checklist (per codeunit)**
- [ ] `[Test]` → `[TestDataSource(Codeunit::"AIT Test Data Source", '<dataset>')]`
- [ ] add the `context: interface "AIT Test Case Context"` parameter
- [ ] drop the `Codeunit "AIT Test Context"` variable; use `context`
- [ ] add `TestHandlers = "AIT Test Handler"` to the codeunit
- [ ] whole-codeunit only (no mixed styles)
- [ ] verify via the platform runner (AL Test Tool / `al runtests`) — cases appear as `Method[caseName]`

### Defining Datasets
Datasets are provided as `.jsonl` or `.yaml` files where each line/entry represents an eval case.

There's no fixed structure required for each line, but using certain formatting will allow easier access to data and name and description definition.

See the `AIT Test Context` for the full API.

#### Example

```
{"name": "Eval01", "question": "A question", "expected_data": 5}
{"name": "Eval02", "question": "A second question", "expected_data": 2}
{"name": "Eval03", "question": "A third question", "expected_data": 2}
```

In this example
1. Setting `name` for each line, that will be used in the BC Copilot Eval Toolkit when uploading the dataset
1. Setting `question` for each line, we can use `AITestContext.GetQuestion()` in the test codeunit, to get the question directly
1. Setting `expected_data` for each line, we can use the `AITestContext.GetExpectedData()` in the test codeunit, to get the question directly