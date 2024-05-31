Shader "MyURP/Tanslucent"
{
    Properties
    {
        _BaseColor("Base Color",color) = (1,1,1,1)
        _BaseMap("Base Map", 2D) = "white" {}
        [Header(Trnaslucent)]
        _NormalDistortion("Normal Distortion", range(0,1)) = 0.5
        _Attenuation("Attenuation", float) = 2
        _Strength("Strength", float) = 2
        [Header(HighLight)]
        _Specular("Specular", float) = 1
        _Shininess("Shininess", float) = 1
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
            Name "Translucent"

            HLSLPROGRAM

            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog
            #pragma multi_compile _ _ADDITIONAL_LIGHTS

            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"
 
            struct Attributes
            {
                float4 positionOS       : POSITION;
                float2 uv               : TEXCOORD0;
                float3 normalOS         : NORMAL;
            };
 
            struct Varyings
            {
                float4 positionCS       : SV_POSITION;
                float2 uv               : TEXCOORD0;
                float fogCoord          : TEXCOORD1;
                float3 normalWS         : TEXCOORD2;
                float3 viewWS           : TEXCOORD3;
                float3 positionWS       : TEXCOORD4;
            };
 
            CBUFFER_START(UnityPerMaterial)
            half4 _BaseColor;
            float4 _BaseMap_ST;

            half _NormalDistortion;
            half _Attenuation;
            half _Strength;

            half _Specular;
            half _Shininess;
            CBUFFER_END
            TEXTURE2D (_BaseMap);SAMPLER(sampler_BaseMap);
 
            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;
 
                o.positionCS = TransformObjectToHClip(v.positionOS.xyz);
                o.uv = TRANSFORM_TEX(v.uv, _BaseMap);
                o.normalWS = TransformObjectToWorldNormal(v.normalOS);
                o.positionWS = TransformObjectToWorld(v.positionOS.xyz);
                o.viewWS = normalize(_WorldSpaceCameraPos - o.positionWS);
                o.fogCoord = ComputeFogFactor(o.positionCS.z);
 
                return o;
            }

            half LightingTranslucent(half3 L, half3 N, half3 V)
            {
                //透射
                half3 H = L + N * _NormalDistortion;
                half _LdotV = dot(-H, V);
                half I = pow(saturate(_LdotV), _Attenuation) * _Strength;
                return I;
            }
 
            half4 frag(Varyings i) : SV_Target
            {
                half4 c;

                half4 baseMap = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, i.uv);
                c = baseMap * _BaseColor;
                
                //Specular = Ks * pow(max(0, dot(N, H)), Shininess)
                Light light = GetMainLight();
                half3 L = light.direction;
                half3 N = i.normalWS;
                half3 V = i.viewWS;
                half3 H = normalize(L + V);
                half NdotH = dot(N, H);
                half specular = _Specular * pow(max(0, NdotH), _Shininess);
                c.rgb *= saturate(dot(N, L));//漫反射
                c.rgb += specular;//高光

                c.rgb += LightingTranslucent(L, N, V) * light.color;//主光透射

                #ifdef _ADDITIONAL_LIGHTS//额外光透射
                    uint pixelLightCount = GetAdditionalLightsCount();
                    for(uint idx = 0u; idx < pixelLightCount; idx++)
                    {
                        Light l = GetAdditionalLight(idx, i.positionWS);
                        half3 attenColor = l.color * l.distanceAttenuation * l.shadowAttenuation;
                        c.rgb += LightingTranslucent(l.direction, N, V) * l.color * attenColor;
                    }
                #endif

                c.rgb = MixFog(c.rgb, i.fogCoord);

                return c;
            }
            ENDHLSL
        }
    }
}