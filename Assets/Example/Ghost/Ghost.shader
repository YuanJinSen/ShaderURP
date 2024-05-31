Shader "Unlit/Ghost"
{
    Properties
    {
        _Data("Fade(x)Intensity(y)Top(z)Offset(w)", vector) = (4,1.25,0,0)
        _FresnelColor("Fresnal Color", color) = (1,1,1,1)
        [Toggle]_GRADUAL("Gradual", int) = 0
    }
    SubShader
    {
        Tags 
        { 
            "RenderPipeline"="UniversalPipeline"
            "Queue"="Transparent"
            "RenderType"="Transparent"
        }
        Blend One One
        ZWrite Off
        LOD 100

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile _ _GRADUAL_ON

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 vertex : POSITION;
                half3 normalOS : NORMAL;//Object Speace
            };

            struct Varyings
            {
                float4 vertex : SV_POSITION;
                half3 normalWS : TEXCOORD0;//World Space
                half3 vertexWS : TEXCOORD1;
                #if _GRADUAL_ON
                    half4 vertexOS : TEXCOORD2;
                #endif
            };

            CBUFFER_START(UnityPerMaterial)
            half4 _Data;
            half4 _FresnelColor;
            CBUFFER_END

            Varyings vert (Attributes v)
            {
                Varyings o;
                o.vertex = TransformObjectToHClip(v.vertex);
                o.vertex.x += sin((_Time.y + o.vertex.y) * 3) * 0.05;
                o.normalWS = TransformObjectToWorldNormal(v.normalOS);
                o.vertexWS = TransformObjectToWorld(v.vertex);
                #if _GRADUAL_ON
                    o.vertexOS = v.vertex;
                #endif
                return o;
            }

            half4 frag (Varyings i) : SV_Target
            {
                half4 c;
                //Õ‚∑¢π‚
                half3 N = normalize(i.normalWS);
                half3 V = normalize(_WorldSpaceCameraPos - i.vertexWS);
                half dotNV = 1 - saturate(dot(V, N));
                half4 fresnal = pow(dotNV, _Data.x) * _Data.y * _FresnelColor;
                c = fresnal;
                //---
                half mask = 1;
                #if _GRADUAL_ON
                    mask = saturate(i.vertexOS.y + i.vertexOS.z + _Data.w);
                    c *= mask;
                #endif
                c = lerp(c, _FresnelColor * mask, mask * _Data.z);
                return c;
            }
            ENDHLSL
        }
    }
}
