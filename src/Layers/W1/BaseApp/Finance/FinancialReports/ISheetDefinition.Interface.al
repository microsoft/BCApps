namespace Microsoft.Finance.FinancialReports;

using Microsoft.CashFlow.Forecast;
using Microsoft.Finance.Analysis;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Budget;
using Microsoft.Finance.GeneralLedger.Ledger;

interface ISheetDefinition
{
    /// <summary>
    /// Populate the sheet definition line buffer from the sheet definition name. Each line represents one sheet in the report and should be filtered accordingly.
    /// </summary>
    /// <param name="SheetDefName">Source sheet definition name</param>
    /// <param name="TempSheetDefLine">Resulting sheet definition line buffer</param>
    procedure PopulateLineBufferForReporting(SheetDefName: Record "Sheet Definition Name"; var TempSheetDefLine: Record "Sheet Definition Line")

    /// <summary>
    /// Filter the G/L entry record by the sheet definition line's totaling fields.
    /// </summary>
    /// <param name="SheetDefLine">Source sheet definition line</param>
    /// <param name="GLEntry">Filtered G/L entry</param>
    procedure FilterGLEntryBySheetTotaling(SheetDefLine: Record "Sheet Definition Line"; var GLEntry: Record "G/L Entry")

    /// <summary>
    /// Filter the G/L budget entry record by the sheet definition line's totaling fields.
    /// </summary>
    /// <param name="SheetDefLine">Source sheet definition line</param>
    /// <param name="GLBudgetEntry">Filtered G/L budget entry</param>
    procedure FilterGLBudgetEntryBySheetTotaling(SheetDefLine: Record "Sheet Definition Line"; var GLBudgetEntry: Record "G/L Budget Entry")

    /// <summary>
    /// Filter the cash flow forecast entry record by the sheet definition line's totaling fields.
    /// </summary>
    /// <param name="SheetDefLine">Source sheet definition line</param>
    /// <param name="CFForecastEntry">Filtered cash flow forecast entry</param>
    procedure FilterCFEntryBySheetTotaling(SheetDefLine: Record "Sheet Definition Line"; var CFForecastEntry: Record "Cash Flow Forecast Entry")

    /// <summary>
    /// Filter the analysis view entry record by the sheet definition line's totaling fields.
    /// </summary>
    /// <param name="SheetDefLine">Source sheet definition line</param>
    /// <param name="AnalysisViewEntry">Filtered analysis view entry</param>
    procedure FilterAnalysisViewEntryBySheetTotaling(SheetDefLine: Record "Sheet Definition Line"; var AnalysisViewEntry: Record "Analysis View Entry")

    /// <summary>
    /// Filter the analysis view budget entry record by the sheet definition line's totaling fields.
    /// </summary>
    /// <param name="SheetDefLine">Source sheet definition line</param>
    /// <param name="AnalysisViewBudgetEntry">Filtered analysis view budget entry</param>
    procedure FilterAnalysisViewBudgetEntryBySheetTotaling(SheetDefLine: Record "Sheet Definition Line"; var AnalysisViewBudgetEntry: Record "Analysis View Budget Entry")

    /// <summary>
    /// Convert the sheet type value to text. This is displayed on the sheet definition page.
    /// </summary>
    /// <param name="SheetDefName">Source sheet definition name</param>
    /// <param name="Type">Sheet type to convert</param>
    /// <param name="Text">Resulting text value</param>
    /// <returns></returns>
    procedure SheetTypeToText(SheetDefName: Record "Sheet Definition Name"; Type: Enum "Sheet Type"; var Text: Text): Boolean

    /// <summary>
    /// Convert the text value to a sheet type. This is used when validating user input on the sheet definition page.
    /// </summary>
    /// <param name="SheetDefName">Source sheet definition name</param>
    /// <param name="Text">Text value to convert</param>
    /// <param name="Type">Resulting sheet type</param>
    procedure TextToSheetType(SheetDefName: Record "Sheet Definition Name"; Text: Text; var Type: Enum "Sheet Type"): Boolean

    /// <summary>
    /// Populate the dimension selection buffer for looking up sheet totaling values. Values are dynamically generated based on the source data, such as shortcut dimensions.
    /// </summary>
    /// <param name="SheetDefName">Source sheet definition name</param>
    /// <param name="Type">Source sheet type</param>
    /// <param name="DimSelection">Resulting dimension selection buffer</param>
    procedure InsertBufferForSheetTotalingLookup(SheetDefName: Record "Sheet Definition Name"; Type: Enum "Sheet Type"; var DimSelection: Page "Dimension Selection")
}