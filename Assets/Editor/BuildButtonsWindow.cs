using System;
using System.IO;
using System.Linq;
using UnityEditor;
using UnityEditor.Build.Reporting;
using UnityEngine;

public class BuildButtonsWindow : EditorWindow
{
    private const string SteamDeckBuildFolder = "steam-deck-build";
    private const string WebBuildFolder = "web-build";
    private const string SteamDeckExecutableName = "steam-deck.x86_64";

    [MenuItem("Tools/Builds/Open Build Buttons")]
    public static void OpenWindow()
    {
        GetWindow<BuildButtonsWindow>("Build Buttons");
    }

    private void OnGUI()
    {
        EditorGUILayout.LabelField("Build Outputs", EditorStyles.boldLabel);
        EditorGUILayout.HelpBox(
            "Create a Steam Deck build or a WebGL build with one click. Artifacts are written to dedicated folders at the project root.",
            MessageType.Info);

        using (new EditorGUILayout.VerticalScope("box"))
        {
            EditorGUILayout.LabelField("Steam Deck", EditorStyles.boldLabel);
            EditorGUILayout.LabelField("Output", SteamDeckBuildFolder);

            if (GUILayout.Button("Build Steam Deck", GUILayout.Height(36)))
            {
                BuildSteamDeck();
            }
        }

        EditorGUILayout.Space(8);

        using (new EditorGUILayout.VerticalScope("box"))
        {
            EditorGUILayout.LabelField("Web", EditorStyles.boldLabel);
            EditorGUILayout.LabelField("Output", WebBuildFolder);

            if (GUILayout.Button("Build Web", GUILayout.Height(36)))
            {
                BuildWeb();
            }
        }
    }

    private static void BuildSteamDeck()
    {
        var outputDirectory = Path.Combine(Directory.GetCurrentDirectory(), SteamDeckBuildFolder);
        Directory.CreateDirectory(outputDirectory);

        var buildPlayerOptions = new BuildPlayerOptions
        {
            scenes = GetEnabledScenes(),
            locationPathName = Path.Combine(outputDirectory, SteamDeckExecutableName),
            target = BuildTarget.StandaloneLinux64,
            options = BuildOptions.None
        };

        RunBuild(buildPlayerOptions, "Steam Deck");
    }

    private static void BuildWeb()
    {
        var outputDirectory = Path.Combine(Directory.GetCurrentDirectory(), WebBuildFolder);
        Directory.CreateDirectory(outputDirectory);

        var buildPlayerOptions = new BuildPlayerOptions
        {
            scenes = GetEnabledScenes(),
            locationPathName = outputDirectory,
            target = BuildTarget.WebGL,
            options = BuildOptions.None
        };

        RunBuild(buildPlayerOptions, "Web");
    }

    private static string[] GetEnabledScenes()
    {
        var enabledScenes = EditorBuildSettings.scenes
            .Where(scene => scene.enabled)
            .Select(scene => scene.path)
            .ToArray();

        if (enabledScenes.Length == 0)
        {
            throw new InvalidOperationException("No enabled scenes were found in Build Settings.");
        }

        return enabledScenes;
    }

    private static void RunBuild(BuildPlayerOptions buildPlayerOptions, string buildLabel)
    {
        try
        {
            var report = BuildPipeline.BuildPlayer(buildPlayerOptions);
            var result = report.summary.result;

            if (result == BuildResult.Succeeded)
            {
                EditorUtility.DisplayDialog(
                    $"{buildLabel} Build Complete",
                    $"Built successfully to:\n{buildPlayerOptions.locationPathName}",
                    "OK");
                return;
            }

            EditorUtility.DisplayDialog(
                $"{buildLabel} Build Failed",
                $"Build finished with result: {result}",
                "OK");
        }
        catch (Exception exception)
        {
            Debug.LogError(exception);
            EditorUtility.DisplayDialog(
                $"{buildLabel} Build Failed",
                exception.Message,
                "OK");
        }
    }
}
