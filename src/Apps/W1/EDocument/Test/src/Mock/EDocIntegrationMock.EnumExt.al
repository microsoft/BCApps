#if not CLEAN26
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Test;

using Microsoft.eServices.EDocument;

#pragma warning disable AL0432
enumextension 139616 "E-Doc Integration Mock" extends "E-Document Integration"
{
#pragma warning restore AL0432
#if not CLEAN26
    value(133501; "Mock")
    {
        Implementation = "E-Document Integration" = "E-Doc. Integration Mock";
        ObsoleteTag = '26.0';
        ObsoleteState = Pending;
        ObsoleteReason = 'Obsolete in 26.0';
    }
#endif

}
#endif