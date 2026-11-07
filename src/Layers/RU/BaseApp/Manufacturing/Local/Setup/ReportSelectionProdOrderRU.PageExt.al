#if not CLEAN28
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Setup;

pageextension 12420 ReportSelectionProdOrderRU extends "Report Selection - Prod. Order"
{
    layout
    {
        addafter("Report Caption")
        {
            field(Default; Rec.Default)
            {
                ToolTip = 'Specifies if the report ID is the default for the report selection.';
                ObsoleteReason = 'Prepare for conversion to Manufacturing app.';
                ObsoleteState = Pending;
                ObsoleteTag = '28.0';
            }
       }
    }
}
#endif
