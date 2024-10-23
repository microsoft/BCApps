// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AIEvaluate;

permissionset 50000 "AI Evaluate Tool - Obj"
{
    Assignable = false;
    Access = Public;

    Permissions =
        codeunit "AI Evaluate" = X,
        codeunit "AI Evaluate Impl." = X;
}