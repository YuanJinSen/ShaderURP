Shader "MyURP/CrackUP"
{
    SubShader
    {
        Tags
        {
            "Queue"="Geometry-1"
            "RenderType" = "Opaque"
            "IgnoreProjector" = "True"
            "RenderPipeline" = "UniversalPipeline"
        }
        LOD 100
 
        Pass
        {
            Name "CrackUP"
            Cull Front
            ColorMask 0

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
 
            struct Attributes
            {
                float4 positionOS       : POSITION;
            };
 
            struct Varyings
            {
                float4 positionCS       : SV_POSITION;
            };
 
            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;
 
                o.positionCS = TransformObjectToHClip(v.positionOS.xyz);
 
                return o;
            }
 
            half4 frag(Varyings i) : SV_Target
            {
                return 0;
            }
            ENDHLSL
        }
    }
}