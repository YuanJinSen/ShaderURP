using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace URP
{
    public class WaterColor : MonoBehaviour
    {
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

            Material mtl = GetComponent<MeshRenderer>().sharedMaterial;
            mtl.SetTexture("_RampTex", RampTexture);
        }
    }
}