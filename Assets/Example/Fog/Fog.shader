Shader "MyURP/Fog"
{
    Properties
    {
        _BaseColor("Base Color",color) = (1,1,1,1)
        _Repeat("Repeat", float) = 0
    }
 
    SubShader
    {
        Tags
        {
            "Queue"="Geometry"
            "RenderType" = "Opaque"
            "IgnoreProjector" = "True"
            "RenderPipeline" = "UniversalPipeline"
        }
        LOD 100
 
        Pass
        {
            Name "Fog"

            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog

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
                float fogCoord          : TEXCOORD1;
                float3 positionOS       : TEXCOORD2;
            };
 
            CBUFFER_START(UnityPerMaterial)
            half4 _BaseColor;
            half _Repeat;
            CBUFFER_END
 
            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;
 
                o.positionOS = v.positionOS;
                o.positionCS = TransformObjectToHClip(v.positionOS.xyz);
                o.uv = v.uv * _Repeat;
                o.fogCoord = ComputeFogFactor(o.positionCS.z);
 
                return o;
            }
 
            half4 frag(Varyings i) : SV_Target
            {
                half4 c = _BaseColor;
                c.rgb = MixFog(c.rgb, i.fogCoord);
                return c;
            }

            ENDHLSL
        }
    }
}