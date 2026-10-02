package com.ksaguide.ksa360

import android.content.Intent
import com.google.android.gms.auth.GoogleAuthUtil
import com.google.android.gms.auth.api.signin.GoogleSignIn
import com.google.android.gms.auth.api.signin.GoogleSignInOptions
import com.google.android.gms.common.api.ApiException
import com.google.android.gms.common.api.Scope
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlin.concurrent.thread

class MainActivity : FlutterActivity() {
    private val channelName = "ksa360/google_sign_in"
    private val requestSignIn = 9173
    private val peopleScopes = listOf(
        "https://www.googleapis.com/auth/user.birthday.read",
        "https://www.googleapis.com/auth/user.gender.read",
    )
    private var pending: MethodChannel.Result? = null
    private var requestPeople = true
    private var lastServerClientId = ""

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "signIn" -> startSignIn(call.argument<String>("serverClientId").orEmpty(), result)
                    "signOut" -> signOut(call.argument<String>("serverClientId").orEmpty(), result)
                    else -> result.notImplemented()
                }
            }
    }

    private fun startSignIn(serverClientId: String, result: MethodChannel.Result) {
        if (serverClientId.isEmpty()) {
            result.error("missing_client", "Web client ID is missing", null)
            return
        }
        if (pending != null) {
            result.error("busy", "Sign-in already in progress", null)
            return
        }
        lastServerClientId = serverClientId
        pending = result
        val builder = GoogleSignInOptions.Builder(GoogleSignInOptions.DEFAULT_SIGN_IN)
            .requestEmail()
            .requestProfile()
            .requestIdToken(serverClientId)
        if (requestPeople) {
            for (scope in peopleScopes) {
                builder.requestScopes(Scope(scope))
            }
        }
        startActivityForResult(GoogleSignIn.getClient(this, builder.build()).signInIntent, requestSignIn)
    }

    private fun signOut(serverClientId: String, result: MethodChannel.Result) {
        val builder = GoogleSignInOptions.Builder(GoogleSignInOptions.DEFAULT_SIGN_IN)
        if (serverClientId.isNotEmpty()) {
            builder.requestIdToken(serverClientId)
        }
        GoogleSignIn.getClient(this, builder.build())
            .signOut()
            .addOnCompleteListener { result.success(true) }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != requestSignIn) return
        val reply = pending
        pending = null
        if (reply == null) return
        if (data == null) {
            reply.success(null)
            return
        }
        try {
            val account = GoogleSignIn.getSignedInAccountFromIntent(data)
                .getResult(ApiException::class.java)
            val idToken = account?.idToken
            if (idToken.isNullOrEmpty()) {
                reply.error("no_token", "Google did not return a sign-in token", null)
                return
            }
            val googleAccount = account.account
            if (googleAccount == null) {
                reply.success(hashMapOf("idToken" to idToken, "accessToken" to ""))
                return
            }
            thread {
                val accessToken = try {
                    GoogleAuthUtil.getToken(
                        this,
                        googleAccount,
                        "oauth2:email profile ${peopleScopes.joinToString(" ")}",
                    )
                } catch (_: Exception) {
                    ""
                }
                runOnUiThread {
                    reply.success(
                        hashMapOf(
                            "idToken" to idToken,
                            "accessToken" to accessToken,
                        ),
                    )
                }
            }
        } catch (error: ApiException) {
            if (error.statusCode == 12501) {
                reply.success(null)
            } else if (requestPeople && lastServerClientId.isNotEmpty() &&
                (error.statusCode == 10 || error.statusCode == 12500)
            ) {
                requestPeople = false
                startSignIn(lastServerClientId, reply)
            } else {
                reply.error(
                    "google_${error.statusCode}",
                    error.message ?: "Google sign-in failed",
                    error.statusCode,
                )
            }
        } catch (error: Exception) {
            reply.error("google", error.message, null)
        }
    }
}
