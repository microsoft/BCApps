// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.TestLibraries.RedTeamScan;

/// <summary>
/// Configuration builder for Red Team scans. Set up locale, risk categories,
/// attack strategies, custom seed prompts, and objectives before passing to
/// Red Team Scan.Start().
/// </summary>
codeunit 135608 "Red Team Scan Config"
{
    var
        ScanLocale: Text;
        RiskCategories: List of [Text];
        AttackStrategies: JsonArray;
        CustomAttackSeedPrompts: JsonArray;
        ScanNumObjectives: Integer;
        ScanBaseUri: Text;

    /// <summary>
    /// Sets the locale for the red team scan.
    /// </summary>
    /// <param name="Locale">The locale code (e.g., 'en', 'es', 'fr').</param>
    procedure SetLocale(Locale: Text)
    begin
        ScanLocale := Locale;
    end;

    /// <summary>
    /// Adds a risk category to the red team scan.
    /// Available categories: Violence, HateUnfairness, Sexual, SelfHarm, ProtectedMaterial, CodeVulnerability, UngroundedAttributes
    /// </summary>
    /// <param name="RiskCategory">The risk category to add.</param>
    procedure AddRiskCategory(RiskCategory: Text)
    begin
        if not RiskCategories.Contains(RiskCategory) then
            RiskCategories.Add(RiskCategory);
    end;

    /// <summary>
    /// Adds an attack strategy to the red team scan.
    /// Each strategy is applied independently to baseline queries.
    /// Available strategies: Flip, Base64, ROT13, CharacterSpace, UnicodeConfusable, CharSwap, Morse, Leetspeak, Url, Binary, EASY, MODERATE, DIFFICULT
    /// Note: MultiTurn and Crescendo must be the sole strategy in a scan.
    /// </summary>
    /// <param name="AttackStrategy">The attack strategy to add.</param>
    procedure AddAttackStrategy(AttackStrategy: Text)
    begin
        AttackStrategies.Add(AttackStrategy);
    end;

    /// <summary>
    /// Adds a composed attack strategy that chains two strategies together.
    /// The first strategy is applied, then the second is applied to the result.
    /// Example: Compose(Base64, ROT13) first encodes in Base64, then applies ROT13.
    /// </summary>
    /// <param name="Strategy1">The first strategy to apply.</param>
    /// <param name="Strategy2">The second strategy to apply to the result of the first.</param>
    procedure AddComposedAttackStrategy(Strategy1: Text; Strategy2: Text)
    var
        ComposedArray: JsonArray;
    begin
        ComposedArray.Add(Strategy1);
        ComposedArray.Add(Strategy2);
        AttackStrategies.Add(ComposedArray);
    end;

    /// <summary>
    /// Adds a custom attack seed prompt for a specific risk type.
    /// Use this to define domain-specific attack scenarios beyond built-in categories.
    /// Supported risk types: violence, sexual, hate_unfairness, self_harm.
    /// </summary>
    /// <param name="RiskType">The risk type (e.g., 'violence', 'hate_unfairness').</param>
    /// <param name="Content">The attack prompt content.</param>
    procedure AddCustomAttackSeedPrompt(RiskType: Text; Content: Text)
    var
        SeedPrompt: JsonObject;
        Metadata: JsonObject;
        TargetHarm: JsonObject;
        TargetHarms: JsonArray;
        Messages: JsonArray;
        Message: JsonObject;
        Sources: JsonArray;
    begin
        TargetHarm.Add('risk-type', RiskType);
        TargetHarm.Add('risk-subtype', '');
        TargetHarms.Add(TargetHarm);

        if ScanLocale <> '' then
            Metadata.Add('lang', ScanLocale)
        else
            Metadata.Add('lang', 'en');
        Metadata.Add('target_harms', TargetHarms);

        Message.Add('role', 'user');
        Message.Add('content', Content);
        Messages.Add(Message);

        Sources.Add('custom');

        SeedPrompt.Add('metadata', Metadata);
        SeedPrompt.Add('messages', Messages);
        SeedPrompt.Add('modality', 'text');
        SeedPrompt.Add('source', Sources);
        SeedPrompt.Add('id', Format(CustomAttackSeedPrompts.Count + 1));

        CustomAttackSeedPrompts.Add(SeedPrompt);
    end;

    /// <summary>
    /// Adds a custom attack seed prompt from a raw JSON object matching the Azure AI SDK format.
    /// Use this when loading seed prompts from a JSON file.
    /// </summary>
    /// <param name="SeedPromptJson">A JsonObject with metadata, messages, modality, source, and id fields.</param>
    procedure AddCustomAttackSeedPrompt(SeedPromptJson: JsonObject)
    begin
        CustomAttackSeedPrompts.Add(SeedPromptJson);
    end;

    /// <summary>
    /// Sets a complete array of custom attack seed prompts from a JSON array.
    /// Use this when loading an entire seed prompts file. Replaces any previously added prompts.
    /// </summary>
    /// <param name="SeedPromptsArray">A JsonArray of seed prompt objects in Azure AI SDK format.</param>
    procedure SetCustomAttackSeedPrompts(SeedPromptsArray: JsonArray)
    begin
        CustomAttackSeedPrompts := SeedPromptsArray;
    end;

    /// <summary>
    /// Sets the number of attack objectives to generate per risk category per attack strategy.
    /// </summary>
    /// <param name="NumObjectives">The number of objectives (default is 5).</param>
    procedure SetNumObjectives(NumObjectives: Integer)
    begin
        ScanNumObjectives := NumObjectives;
    end;

    /// <summary>
    /// Sets the base URI for the red team scan. The default is 'http://localhost:8000'.
    /// </summary>
    /// <param name="Uri">URI to set for base URI.</param>
    procedure SetBaseUri(Uri: Text)
    begin
        ScanBaseUri := Uri;
    end;

    /// <summary>
    /// Gets the configured locale.
    /// </summary>
    /// <returns>The locale code, or empty string if not set.</returns>
    procedure GetLocale(): Text
    begin
        exit(ScanLocale);
    end;

    /// <summary>
    /// Gets the configured risk categories.
    /// </summary>
    /// <returns>A list of risk category names.</returns>
    procedure GetRiskCategories(): List of [Text]
    begin
        exit(RiskCategories);
    end;

    /// <summary>
    /// Gets the configured attack strategies as a JSON array.
    /// Elements are either strings (individual) or nested arrays of two strings (composed).
    /// </summary>
    /// <returns>A JsonArray of attack strategies.</returns>
    procedure GetAttackStrategies(): JsonArray
    begin
        exit(AttackStrategies);
    end;

    /// <summary>
    /// Gets the configured custom attack seed prompts.
    /// </summary>
    /// <returns>A JsonArray of seed prompt objects.</returns>
    procedure GetCustomAttackSeedPrompts(): JsonArray
    begin
        exit(CustomAttackSeedPrompts);
    end;

    /// <summary>
    /// Gets the configured number of objectives.
    /// </summary>
    /// <returns>The number of objectives, or 0 if not set.</returns>
    procedure GetNumObjectives(): Integer
    begin
        exit(ScanNumObjectives);
    end;

    /// <summary>
    /// Gets the configured base URI.
    /// </summary>
    /// <returns>The base URI, or empty string if not set.</returns>
    procedure GetBaseUri(): Text
    begin
        exit(ScanBaseUri);
    end;
}
