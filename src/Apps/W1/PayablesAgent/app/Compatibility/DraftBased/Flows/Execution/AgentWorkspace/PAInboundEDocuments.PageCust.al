// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;
using Microsoft.eServices.EDocument;

pagecustomization "PA Inbound E-Documents" customizes "Inbound E-Documents"
{
    ClearActions = true;
    ClearLayout = true;
    ClearViews = true;
    DeleteAllowed = false;

    layout
    {
        modify("Entry No")
        {
            Visible = true;
        }
        modify("Import Processing Status")
        {
            Visible = true;
        }
    }
    actions
    {
        modify(AnalyzeDocument)
        {
            Visible = true;
        }
        modify(PrepareDraftDocument)
        {
            Visible = true;
        }
        modify(OpenDraftDocument)
        {
            Visible = true;
        }
    }
}
