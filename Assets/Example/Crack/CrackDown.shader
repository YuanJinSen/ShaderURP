Shader "MyURP/CrackDown"
{
    Properties
    {
        _BaseColor("Base Color",color) = (1,1,1,1)
    }
 
    SubShader
    {
        Tags
        {
            "Queue"="Geometry-2"
            "RenderType" = "Opaque"
            "IgnoreProjector" = "True"
            "RenderPipeline" = "UniversalPipeline"
        }
        LOD 100
 
        Pass
        {
            Name "CrackDown"
            Cull Front

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
            };
 
            struct Varyings
            {
                float4 positionCS       : SV_POSITION;
                float3 positionOS       : TEXCOORD0;
                float fogCoord          : TEXCOORD1;
            };
 
            CBUFFER_START(UnityPerMaterial)
            half4 _BaseColor;
            CBUFFER_END
 
            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;
 
                o.positionCS = TransformObjectToHClip(v.positionOS.xyz);
                o.positionOS = v.positionOS.xyz;
                o.fogCoord = ComputeFogFactor(o.positionCS.z);
 
                return o;
            }
 
            half4 frag(Varyings i) : SV_Target
            {
                half4 c = 1;

                half mask = abs(i.positionOS.y);
                float t = sin(_Time.y);
                t = t * 0.3 + 0.7;
                c.rgb = lerp(0, _BaseColor * t, mask);

                return c;
            }
            ENDHLSL
        }
    }
}