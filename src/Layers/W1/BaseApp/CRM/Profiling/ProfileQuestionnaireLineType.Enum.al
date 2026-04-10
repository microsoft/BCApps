// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Profiling;

#pragma warning disable AL0659
enum 5090 "Profile Questionnaire Line Type"
#pragma warning restore AL0659
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Question") { Caption = 'Question'; }
    value(1; "Answer") { Caption = 'Answer'; }
}
