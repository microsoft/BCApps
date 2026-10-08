// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

#pragma warning disable AS0007
namespace Microsoft.Agent.PayablesAgent;

using Microsoft.eServices.EDocument;

codeunit 3330 "PA BC IQ Demo Submit"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    TableNo = "PA BC IQ Demo Batch Doc.";

    trigger OnRun()
    var
        EDocument: Record "E-Document";
        PayablesAgentSetup: Codeunit "Payables Agent Setup";
        ResourceInStream: InStream;
        SourceDetails: Text;
    begin
        SourceDetails := StrSubstNo(SourceDetailsLbl, Format(Rec."Run ID", 0, 4), Rec."File Name");
        NavApp.GetResource(Rec."Resource Path", ResourceInStream);
        PayablesAgentSetup.ImportInvoiceFile(Rec."File Name", SourceDetails, ResourceInStream, EDocument);

        Rec."E-Document Entry No." := EDocument."Entry No";
        Rec."E-Document System ID" := EDocument.SystemId;
        Rec."Unstructured Storage Entry No." := EDocument."Unstructured Data Entry No.";
        Rec."Structured Storage Entry No." := EDocument."Structured Data Entry No.";
        Rec.Modify(true);
    end;

    var
        SourceDetailsLbl: Label 'BC IQ demo %1 | %2', Locked = true, Comment = '%1 = run ID, %2 = file name';
}
