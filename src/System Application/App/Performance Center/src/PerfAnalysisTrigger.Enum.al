// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Tooling;

/// <summary>
/// The kind of UI / API / background trigger the user associates with the slow scenario.
/// </summary>
enum 8407 "Perf. Analysis Trigger"
{
    Access = Public;
    Extensible = false;

    value(0; Unknown) { Caption = 'Not sure'; }
    value(1; OpeningPage) { Caption = 'Opening a page'; }
    value(2; ActionOnPage) { Caption = 'Pressing a button on a page'; }
    value(3; FieldValidation) { Caption = 'Entering a value in a field'; }
    value(4; WebApiCall) { Caption = 'A web API call'; }
    value(5; BackgroundJob) { Caption = 'A background job or job queue'; }
    value(6; Other) { Caption = 'Something else'; }
}
