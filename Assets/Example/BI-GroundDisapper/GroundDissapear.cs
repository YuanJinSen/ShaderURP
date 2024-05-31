using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace temp
{
    public class GroundDissapear : MonoBehaviour
    {
        void Start()
        {
            int n = transform.childCount;
            Vector4[] vectors = new Vector4[n];
            for (int i = 0; i < n; i++)
            {
                Transform child = transform.GetChild(i);
                vectors[i] = child.position;
                child.gameObject.SetActive(false);
            }
            Material mtl = GetComponent<MeshRenderer>().sharedMaterial;
            mtl.SetInt("StartPosCount", n);
            mtl.SetVectorArray("StartPosArr", vectors);
        }
    }
}