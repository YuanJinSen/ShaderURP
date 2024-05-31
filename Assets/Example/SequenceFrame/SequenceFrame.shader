Shader "MyURP/SequenceFrame"
{
    Properties
    {
        _BaseColor("Base Color",color) = (1,1,1,1)
        _BaseMap("BaseMap", 2D) = "white" {}
        _Size("W(x)H(y)Frame(z)", vector) = (1,1,0,0)
        _VerticalBillboarding("VerticalBillboarding", float) = 1
    }
 
    SubShader
    {
        Tags
        {
            "Queue"="Transparent"
            "RenderType" = "Opaque"
            "IgnoreProjector" = "True"
            "RenderPipeline" = "UniversalPipeline"
        }
        LOD 100
        Blend SrcAlpha OneMinusSrcAlpha
 
        Pass
        {
            Name "SequenceFrame"

            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"
 
            struct Attributes
            {
                float4 positionOS       : POSITION;
                float2 uv               : TEXCOORD0;
            };
 
            struct Varyings
            {
                float4 positionCS       : SV_POSITION;
                float2 uv               : TEXCOORD0;
            };
 
            CBUFFER_START(UnityPerMaterial)
            half4 _BaseColor;
            half4 _Size;
            half _VerticalBillboarding;
            float4 _BaseMap_ST;
            CBUFFER_END
            TEXTURE2D (_BaseMap);SAMPLER(sampler_BaseMap);

            float4 LookAtCamera(float3 positionOS)
            {
                float3 normalDir = TransformWorldToObject(_WorldSpaceCameraPos);//mul(GetWorldToObjectMatrix(), );
                normalDir = -normalize(normalDir);
                normalDir.y *= _VerticalBillboarding;

                float3 upDir = float3(0,1,0);
                float3 rightDir = normalize(cross(upDir, normalDir));
                upDir = normalize(cross(normalDir, rightDir));

                float3 localPos = rightDir * positionOS.x + upDir * positionOS.y + normalDir * positionOS.z;

                return TransformObjectToHClip(localPos);
            }

            float2 GetSequenceFrameUV(float2 uv, half index)
            {
                index %= _Size.x * _Size.y;

                uv.x = (uv.x + floor(index) % _Size.y) / _Size.x;
                uv.y = (uv.y + _Size.y - ceil(index / _Size.x)) / _Size.y;

                return uv;
            }
 
            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;
 
                o.positionCS = LookAtCamera(v.positionOS.xyz);
                o.uv = GetSequenceFrameUV(v.uv, _Time.y * _Size.z);
 
                return o;
            }
 
            half4 frag(Varyings i) : SV_Target
            {
                half4 c;

                half4 baseMap = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, i.uv);
                c = baseMap * _BaseColor;

                return c;
            }
            ENDHLSL
        }
    }
}