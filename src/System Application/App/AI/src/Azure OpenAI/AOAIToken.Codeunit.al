namespace System.AI;

/// <summary>
/// Provides functionality to get the token count for an input according to the model family they'd be used with.
/// </summary>
codeunit 7759 "AOAI Token"
{
    InherentEntitlements = X;
    InherentPermissions = X;
    Access = Public;

    var
        AzureOpenAIImpl: Codeunit "Azure OpenAI Impl";
        Encodingcl100kbaseLbl: Label 'cl100k_base', Locked = true;
        Encodingp50kbaseLbl: Label 'p50k_base', Locked = true;

    /// <summary>
    /// Gets the token count for the input according to GPT3.5 models.
    /// </summary>
    /// <param name="Input">The input to get the token count for.</param>
    /// <returns>The token count.</returns>
    procedure GetGPT35TokenCount(Input: SecretText): Integer
    begin
        exit(AzureOpenAIImpl.GetTokenCount(Input, Encodingcl100kbaseLbl));
    end;

    /// <summary>
    /// Gets the token count for the input according to GPT4 models.
    /// </summary>
    /// <param name="Input">The input to get the token count for.</param>
    /// <returns>The token count.</returns>
    procedure GetGPT4TokenCount(Input: SecretText): Integer
    begin
        exit(AzureOpenAIImpl.GetTokenCount(Input, Encodingcl100kbaseLbl));
    end;

    /// <summary>
    /// Gets the token count for the input according to embedding Ada models.
    /// </summary>
    /// <param name="Input">The input to get the token count for.</param>
    /// <returns>The token count.</returns>
    procedure GetAdaTokenCount(Input: SecretText): Integer
    begin
        exit(AzureOpenAIImpl.GetTokenCount(Input, Encodingcl100kbaseLbl));
    end;

    /// <summary>
    /// Gets the token count for the input according to text Davinci models.
    /// </summary>
    /// <param name="Input">The input to get the token count for.</param>
    /// <returns>The token count.</returns>
    procedure GetDavinciTokenCount(Input: SecretText): Integer
    begin
        exit(AzureOpenAIImpl.GetTokenCount(Input, Encodingp50kbaseLbl));
    end;
}