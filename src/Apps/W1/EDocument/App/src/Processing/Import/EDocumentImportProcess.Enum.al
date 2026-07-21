// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Import;

enum 6156 "E-Document Import Process"
{
    Extensible = false;

#if not CLEAN29
    value(0; "Version 1.0")
    {
        Caption = 'Version 1.0';
        ObsoleteState = Pending;
        ObsoleteReason = 'v1 import is deprecated; all services use the v2 draft pipeline.';
        ObsoleteTag = '29.0';
    }
#endif
    value(1; "Version 2.0")
    {
        Caption = 'Version 2.0';
    }
}