// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.DynamicsFieldService;

using Microsoft.Integration.Dataverse;
using Microsoft.Projects.Project.Job;

tableextension 6611 "FS Job Task" extends "Job Task"
{
    fields
    {
#pragma warning disable AS0099 // Preserve the existing field ID for compatibility.
        field(12000; "Coupled to FS"; Boolean)
        {
            FieldClass = FlowField;
            Caption = 'Coupled to Field Service';
            Editable = false;
            CalcFormula = exist("CRM Integration Record" where("Integration ID" = field(SystemId), "Table ID" = const(Database::"Job Task")));
        }
#pragma warning restore AS0099
    }
}