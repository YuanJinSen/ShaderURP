using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace temp
{
    public class Frame : MonoBehaviour
    {
        Material material;
        int frameCount;

        void Start()
        {
            material = GetComponent<MeshRenderer>().material;    
        }

        void Update()
        {
            frameCount++;
            //material.SetFloat("_Frame", frameCount);
        }
    }
}