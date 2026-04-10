namespace Microsoft.Finance.FinancialReports;

using Microsoft.CashFlow.Forecast;
using Microsoft.Finance.Analysis;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Budget;
using Microsoft.Finance.GeneralLedger.Ledger;

interface IDimensionPerspective
{
    /// <summary>
    /// Populate the dimension perspective line buffer from the dimension perspective name. Each line represents one perspective in the report and should be filtered accordingly.
    /// </summary>
    /// <param name="DimPerspectiveName">Source dimension perspective name</param>
    /// <param name="TempDimPerspectiveLine">Resulting dimension perspective line buffer</param>
    procedure PopulateLineBufferForReporting(DimPerspectiveName: Record "Dimension Perspective Name"; var TempDimPerspectiveLine: Record "Dimension Perspective Line")

    /// <summary>
    /// Filter the G/L entry record by the dimension perspective line's totaling fields.
    /// </summary>
    /// <param name="DimPerspectiveLine">Source dimension perspective line</param>
    /// <param name="GLEntry">Filtered G/L entry</param>
    procedure FilterGLEntryByPerspectiveTotaling(DimPerspectiveLine: Record "Dimension Perspective Line"; var GLEntry: Record "G/L Entry")

    /// <summary>
    /// Filter the G/L budget entry record by the dimension perspective line's totaling fields.
    /// </summary>
    /// <param name="DimPerspectiveLine">Source dimension perspective line</param>
    /// <param name="GLBudgetEntry">Filtered G/L budget entry</param>
    procedure FilterGLBudgetEntryByPerspectiveTotaling(DimPerspectiveLine: Record "Dimension Perspective Line"; var GLBudgetEntry: Record "G/L Budget Entry")

    /// <summary>
    /// Filter the cash flow forecast entry record by the dimension perspective line's totaling fields.
    /// </summary>
    /// <param name="DimPerspectiveLine">Source dimension perspective line</param>
    /// <param name="CFForecastEntry">Filtered cash flow forecast entry</param>
    procedure FilterCFEntryByPerspectiveTotaling(DimPerspectiveLine: Record "Dimension Perspective Line"; var CFForecastEntry: Record "Cash Flow Forecast Entry")

    /// <summary>
    /// Filter the analysis view entry record by the dimension perspective line's totaling fields.
    /// </summary>
    /// <param name="DimPerspectiveLine">Source dimension perspective line</param>
    /// <param name="AnalysisViewEntry">Filtered analysis view entry</param>
    procedure FilterAnalysisViewEntryByPerspectiveTotaling(DimPerspectiveLine: Record "Dimension Perspective Line"; var AnalysisViewEntry: Record "Analysis View Entry")

    /// <summary>
    /// Filter the analysis view budget entry record by the dimension perspective line's totaling fields.
    /// </summary>
    /// <param name="DimPerspectiveLine">Source dimension perspective line</param>
    /// <param name="AnalysisViewBudgetEntry">Filtered analysis view budget entry</param>
    procedure FilterAnalysisViewBudgetEntryByPerspectiveTotaling(DimPerspectiveLine: Record "Dimension Perspective Line"; var AnalysisViewBudgetEntry: Record "Analysis View Budget Entry")

    /// <summary>
    /// Convert the perspective type value to text. This is displayed on the dimension perspective page.
    /// </summary>
    /// <param name="DimPerspectiveName">Source dimension perspective name</param>
    /// <param name="Type">Perspective type to convert</param>
    /// <param name="Text">Resulting text value</param>
    /// <returns></returns>
    procedure PerspectiveTypeToText(DimPerspectiveName: Record "Dimension Perspective Name"; Type: Enum "Dimension Perspective Type"; var Text: Text): Boolean

    /// <summary>
    /// Convert the text value to a perspective type. This is used when validating user input on the dimension perspective page.
    /// </summary>
    /// <param name="DimPerspectiveName">Source dimension perspective name</param>
    /// <param name="Text">Text value to convert</param>
    /// <param name="Type">Resulting perspective type</param>
    procedure TextToPerspectiveType(DimPerspectiveName: Record "Dimension Perspective Name"; Text: Text; var Type: Enum "Dimension Perspective Type"): Boolean

    /// <summary>
    /// Populate the dimension selection buffer for looking up perspective totaling values. Values are dynamically generated based on the source data, such as shortcut dimensions.
    /// </summary>
    /// <param name="DimPerspectiveName">Source dimension perspective name</param>
    /// <param name="Type">Source perspective type</param>
    /// <param name="DimSelection">Resulting dimension selection buffer</param>
    procedure InsertBufferForPerspectiveTotalingLookup(DimPerspectiveName: Record "Dimension Perspective Name"; Type: Enum "Dimension Perspective Type"; var DimSelection: Page "Dimension Selection")
}