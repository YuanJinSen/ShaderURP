using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

namespace URP
{
    public class Cartoon : MonoBehaviour
    {
        public int Ref;
        public Gradient Ramp;
        public Texture2D RampTexture;

        void OnValidate()
        {
            RampTexture = new Texture2D(256, 1);
            RampTexture.wrapMode = TextureWrapMode.Clamp;
            RampTexture.filterMode = FilterMode.Bilinear;
            int n = RampTexture.width;
            Color[] colors = new Color[n];
            for (int i = 0; i < n; i++) colors[i] = Ramp.Evaluate((float)i / n);
            RampTexture.SetPixels(colors);
            RampTexture.Apply();

            var renderers = GetComponentsInChildren<SkinnedMeshRenderer>();
            foreach (var r in renderers)
            {
                Material mtl = r.sharedMaterial;
                mtl.SetInt("_Ref", Ref);
                mtl.SetTexture("_ShadowRampTex", RampTexture);
            }
        }
    }
    public class PlugTangentTools
    {
        [MenuItem("Tools/模型平均法线写入切线数据")]
        public static void WirteAverageNormalToTangentToos()
        {
            MeshFilter[] meshFilters = Selection.activeGameObject.GetComponentsInChildren<MeshFilter>();
            foreach (var meshFilter in meshFilters)
            {
                Mesh mesh = meshFilter.sharedMesh;
                WirteAverageNormalToTangent(mesh);
            }

            SkinnedMeshRenderer[] skinMeshRenders = Selection.activeGameObject.GetComponentsInChildren<SkinnedMeshRenderer>();
            foreach (var skinMeshRender in skinMeshRenders)
            {
                Mesh mesh = skinMeshRender.sharedMesh;
                WirteAverageNormalToTangent(mesh);
            }
        }

        private static void WirteAverageNormalToTangent(Mesh mesh)
        {
            var averageNormalHash = new Dictionary<Vector3, Vector3>();
            for (var j = 0; j < mesh.vertexCount; j++)
            {
                if (!averageNormalHash.ContainsKey(mesh.vertices[j]))
                {
                    averageNormalHash.Add(mesh.vertices[j], mesh.normals[j]);
                }
                else
                {
                    averageNormalHash[mesh.vertices[j]] =
                        (averageNormalHash[mesh.vertices[j]] + mesh.normals[j]).normalized;
                }
            }

            var averageNormals = new Vector3[mesh.vertexCount];
            for (var j = 0; j < mesh.vertexCount; j++)
            {
                averageNormals[j] = averageNormalHash[mesh.vertices[j]];
            }

            var tangents = new Vector4[mesh.vertexCount];
            for (var j = 0; j < mesh.vertexCount; j++)
            {
                tangents[j] = new Vector4(averageNormals[j].x, averageNormals[j].y, averageNormals[j].z, 0);
            }
            mesh.tangents = tangents;
        }
    }
}