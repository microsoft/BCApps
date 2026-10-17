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

The _AI Eval Command Line Runner_ can export structured run data for the latest suite version. Repeatedly use the _Load Next AI Eval Run Data File_ action and read the _AI Eval Run Data File_, _AI Eval Run Data File Path_, and _AI Eval Run Data File Error_ fields until the content contains `No more AI Eval run data files.`. Pass `-ExportAITRunData` to `Invoke-AITTests` to make the PowerShell test runner perform this loop using the existing client session and form. The output defaults to the `AITRunData` folder next to the test runner module and can be changed with `-AITRunDataFolder`.

The export uses the following structure:

```text
<suite>\
  version-<version>\
    results.json
    export-status.json
    <dataset-group-without-extension>-<test-input-code>\
      evaluation-result-<AI-Eval-log-ID>.json
      agent-task-details\
        task-<Agent-Task-ID>.json
```

`results.json` is the entry point for analysis. Its `exportStatusFile` property identifies the writer's completion report, `export-status.json`. Check this report before treating the package as complete. Each evaluation result contains the original dataset identifiers, input, output, status, metrics, errors, and references to optional Agent Task troubleshooting details. Multiline messages and call stacks retain their line endings and whitespace.

The stream emits `results.json`, then **all evaluation results**, and only then Agent Task details. This ordering does not change the folder hierarchy. Evaluations for the same dataset can reference the same task file, which is emitted once per export; the same task in different dataset folders still has a file in each folder. If a task cannot be exported, its `task-<ID>.json` contains an explicit error object with `agentTaskId`, `exportStatus: "Failed"`, and `error` instead of task details. The _AI Eval Run Data File Error_ field also contains the error, and the next action advances to the next task. Existing Agent Management authorization and troubleshooting redaction checks still apply.

The PowerShell writer creates `export-status.json` with `InProgress` status, tracks written files and errors, and records `Completed` only after receiving the final sentinel without failures. Recoverable file errors, task-detail errors, timeouts, and exceptions produce `Partial` status with diagnostic details. An interrupted process can leave `InProgress`; neither that nor a missing status file indicates a complete export. Export status is separate from evaluation success or failure. Programmatic consumers implementing their own download loop must maintain this writer-owned completion report; it is not emitted by the AL action.

Known dataset file extensions are removed only from folder names; persisted dataset codes are unchanged. Generated dataset folder components longer than 255 characters are abbreviated. Dictionary mappings reuse the same names throughout an export, reserving ordinary names before allocating abbreviations and adding `-2`, `-3`, and subsequent suffixes for collisions. Distinct original group/input pairs remain distinct even when extension removal or joining their names produces a collision. The same serializer instance is used for the summary and subsequent file paths so that all relative references agree. Actual suite codes are limited to 10 characters, so suite folders need no abbreviation or persistent mapping file.

Existing data for the exact same suite version is deleted before that version is exported again; other suites and versions are preserved. The export loop has a 20-minute deadline checked between actions; it does not cancel an action already in progress. A deeply nested output root can still exceed a runtime's full-path limit; use a shorter `-AITRunDataFolder` when necessary.

### Export regression coverage

From the repository root, run the standalone PowerShell regression suite with:

```powershell
pwsh -NoProfile -File .\Eng\Core\Tools\ALTestRunner\Tests\AITRunDataExport.Tests.ps1
```

The script also supports Windows PowerShell 5.1 and uses isolated temporary folders and mocked client responses, without a BC instance. The AL test app in `Eng\Core\Tools\ALTestRunner\Tests\AL` covers serializer mappings, BLOB text round trips, and page streaming/reset behavior. Compile it against the current AI Test Toolkit and Library Assert packages, then run codeunit `149052 "AIT Run Data Export Tests"` with the AL test runner in an isolated BC test instance.


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