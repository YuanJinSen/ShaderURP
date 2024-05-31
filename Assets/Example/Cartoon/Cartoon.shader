Shader "MyURP/Cartoon"
{
    Properties
    {
        _BaseColor("Base Color",color) = (1,1,1,1)
        _BaseMap("Base Map", 2D) = "white" {}
        [Header(Outline)]
        _Outline("Outline", Range(0,1)) = 1
        _Ref("Ref", float) = 0
        [Header(Color)]
        _ShadowRampTex("Shadow Ramp Map", 2D) = "white" {}
        [Header(Specular)]
        _Specular("Instensity(x)Range(y)Smooth(z)", vector) = (0,0,0,0)
        [Header(Fresnel)]
        _Fresnel("Instensity(x)Range(y)Smooth(z)", vector) = (1,1,0,0)
        _FresnelColor("Fresnel Color", color) = (1,1,1,1)
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
            Name "Cartoon"
            Stencil
            {
                Ref [_Ref]
                Comp Always
                Pass Replace
            }
            Tags { "LightMode"="UniversalForward" }

            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
            #pragma multi_compile _ _SHADOWS_SOFT

            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"
 
            struct Attributes
            {
                float4 positionOS       : POSITION;
                float3 normalOS         : NORMAL;
                float2 uv               : TEXCOORD0;
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
            float4 _ShadowRampTex_ST;
            half4 _Specular;
            half4 _Fresnel;
            half4 _FresnelColor;
            CBUFFER_END
            TEXTURE2D (_BaseMap);SAMPLER(sampler_BaseMap);
            TEXTURE2D (_ShadowRampTex);SAMPLER(sampler_ShadowRampTex);
 
            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;
 
                o.positionWS = TransformObjectToWorld(v.positionOS.xyz);
                o.viewWS = normalize(_WorldSpaceCameraPos - o.positionWS);
                o.positionCS = TransformObjectToHClip(v.positionOS.xyz);
                o.normalWS = TransformObjectToWorldNormal(v.normalOS);
                o.uv = TRANSFORM_TEX(v.uv, _BaseMap);
                o.fogCoord = ComputeFogFactor(o.positionCS.z);
 
                return o;
            }
 
            half4 frag(Varyings i) : SV_Target
            {
                half4 c;

                half4 baseMap = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, i.uv);
                c = baseMap * _BaseColor;

                //使用Lambert求出片段0~1的明暗
                //然后再使用Step做出硬边的明暗
                Light mainLight = GetMainLight(TransformWorldToShadowCoord(i.positionWS));
                half3 L = mainLight.direction;
                half3 N = normalize(i.normalWS);
                half NdotL = dot(N, L) * 0.5 + 0.5;
                half ramp = SAMPLE_TEXTURE2D(_ShadowRampTex, sampler_ShadowRampTex, half2(1-NdotL, 0));
                ramp *= mainLight.shadowAttenuation * 0.5 + 0.5;
                c = lerp(c * ramp, c, ramp);

                //高光
                half3 V = i.viewWS;
                half3 H = normalize(L + V);
                half NdotH = dot(N, H);
                half specular = _Specular.x * pow(NdotH, _Specular.y);
                specular = smoothstep(0.5, 0.5 + _Specular.z, specular);
                c += specular;

                //外发光
                half NdotV = 1 -  saturate(dot(N, V));
                half fresnal = _Fresnel.x * pow(NdotV, _Fresnel.y);
                fresnal = smoothstep(0.5, 0.5 + _Fresnel.z, fresnal);
                c += _FresnelColor * fresnal;

                c.rgb = MixFog(c.rgb, i.fogCoord);
                return c;
            }
            ENDHLSL
        }

        Pass
        {
            Name "Outline"
            Stencil
            {
                Ref [_Ref]
                Comp NotEqual
            }
            Tags { "LightMode"="Outline" }
            Cull Front

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
 
            struct Attributes
            {
                float4 positionOS       : POSITION;
                float3 tangentOS        : TANGENT;
                float4 color            : COLOR;
            };
 
            struct Varyings
            {
                float4 positionCS       : SV_POSITION;
                float fogCoord          : TEXCOORD0;
                float4 color            : TEXCOORD1;
            };

            CBUFFER_START(UnityPerMaterial)
            half _Outline;
            CBUFFER_END
 
            Varyings vert(Attributes v)
            {
                Varyings o = (Varyings)0;

                float3 positionWS = TransformObjectToWorld(v.positionOS);
                float distance = length(_WorldSpaceCameraPos - positionWS);
                float3 positionOS = v.positionOS.xyz;
                //0.使用C#脚本，将平均后的法线值存到切线中
                //1.根据_Outline * 0.01可以自定义描边粗细
                //2.distance可以让描边在远近距离粗细一样
                //3.顶点色的Alpha值可以用来存储想要的粗细
                positionOS += normalize(v.tangentOS) * _Outline * 0.01 * distance;

                o.color = v.color;
                o.positionCS = TransformObjectToHClip(positionOS);
                o.fogCoord = ComputeFogFactor(o.positionCS.z);
 
                return o;
            }
 
            half4 frag(Varyings i) : SV_Target
            {
                //顶点色的RGB值可以用来存储描边颜色
                return MixFog(i.color, i.fogCoord).x;
            }
            ENDHLSL
        }

        Pass
        {
            Name "ShadowCaster"
            Tags{"LightMode" = "ShadowCaster"}

            ZWrite On
            ZTest LEqual
            ColorMask 0
            Cull[_Cull]

            HLSLPROGRAM
            #pragma exclude_renderers gles gles3 glcore
            #pragma target 4.5

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma shader_feature_local_fragment _GLOSSINESS_FROM_BASE_ALPHA

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #pragma multi_compile _ DOTS_INSTANCING_ON

            // -------------------------------------
            // Universal Pipeline keywords

            // This is used during shadow map generation to differentiate between directional and punctual light shadows, as they use different formulas to apply Normal Bias
            #pragma multi_compile_vertex _ _CASTING_PUNCTUAL_LIGHT_SHADOW

            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment

            #include "Packages/com.unity.render-pipelines.universal/Shaders/SimpleLitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/ShadowCasterPass.hlsl"
            ENDHLSL
        }

    }
}