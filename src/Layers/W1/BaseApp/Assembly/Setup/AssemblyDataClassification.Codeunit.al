// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Assembly.Setup;

using Microsoft.Assembly.Comment;
using Microsoft.Assembly.Document;
using Microsoft.Assembly.History;
using Microsoft.Assembly.Reports;
using Microsoft.Utilities;
using System.Privacy;

codeunit 1761 "Assembly-Data Classification"
{
    var
        DataClassificationMgt: Codeunit "Data Classification Mgt.";

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Data Classification Eval. Data", 'OnCreateEvaluationDataOnAfterClassifyTablesToNormal', '', false, false)]
    local procedure OnClassifyTables()
    begin
        ClassifyTables();
    end;

    local procedure ClassifyTables()
    begin
        ClassifyPostedAssemblyHeader();

        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Assembly Header");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Assembly Line");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Assemble-to-Order Link");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Assembly Setup");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Assembly Comment Line");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Posted Assembly Line");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"Posted Assemble-to-Order Link");
        DataClassificationMgt.SetTableFieldsToNormal(DATABASE::"ATO Sales Buffer");
    end;

    local procedure ClassifyPostedAssemblyHeader()
    var
        DummyPostedAssemblyHeader: Record "Posted Assembly Header";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Posted Assembly Header";
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
        DataClassificationMgt.SetFieldToPersonal(TableNo, DummyPostedAssemblyHeader.FieldNo("User ID"));
    end;


}
