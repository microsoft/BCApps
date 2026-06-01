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