// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.Dataverse;

using System.Threading;

codeunit 5372 "Enable CDS Virtual Tables"
{
    TableNo = "Job Queue Entry";

    trigger OnRun()
    var
        CDSIntegrationImpl: Codeunit "CDS Integration Impl.";
        FilterTxt: Text;
    begin
        FilterTxt := Rec.GetXmlContent();
        CDSIntegrationImpl.EnableVirtualTables(FilterTxt);
    end;
}