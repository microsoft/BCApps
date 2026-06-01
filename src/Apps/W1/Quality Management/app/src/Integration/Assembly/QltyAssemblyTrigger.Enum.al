// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Integration.Assembly;

enum 20457 "Qlty. Assembly Trigger"
{
    Extensible = true;
    Caption = 'Quality Assembly Trigger';

    value(0; NoTrigger)
    {
        Caption = 'Never';
    }
    value(1; OnAssemblyOutputPost)
    {
        Caption = 'When Assembly Output is posted';
    }
}
