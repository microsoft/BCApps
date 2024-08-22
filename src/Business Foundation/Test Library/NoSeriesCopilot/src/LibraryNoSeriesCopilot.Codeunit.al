namespace Microsoft.Foundation.NoSeries.Test;

using Microsoft.Foundation.NoSeries;

codeunit 134520 "Library - No. Series Copilot"
{
    procedure Generate(var NoSeriesGeneration: Record "No. Series Generation"; var NoSeriesGenerationDetail: Record "No. Series Generation Detail"; InputText: Text)
    var 
        NoSeriesCopilotImpl: Codeunit "No. Series Copilot Impl.";
    begin
        NoSeriesCopilotImpl.Generate(NoSeriesGeneration, NoSeriesGenerationDetail, InputText);
    end;
}
