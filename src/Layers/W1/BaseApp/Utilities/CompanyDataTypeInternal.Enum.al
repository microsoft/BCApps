#if not CLEAN26
#pragma warning disable AS0049, AS0072
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Utilities;

enum 9120 "Company Data Type (Internal)"
{
    Extensible = true;
    AssignmentCompatibility = true;
    Access = Internal;
    ObsoleteTag = '25.2';
    ObsoleteReason = 'Changing the way demo data is generated, for more infromation see https://go.microsoft.com/fwlink/?linkid=2288084';
    ObsoleteState = Pending;

    value(0; "Evaluation Data")
    {
        Caption = 'Evaluation Data';
    }
    value(1; "Standard Data")
    {
        Caption = 'Standard Data';
    }
    value(2; "None")
    {
        Caption = 'None';
    }
    value(3; "Extended Data")
    {
        Caption = 'Extended Data';
    }
    value(4; "Full No Data")
    {
        Caption = 'Full No Data';
    }
}
#pragma warning restore AS0049, AS0072
#endif