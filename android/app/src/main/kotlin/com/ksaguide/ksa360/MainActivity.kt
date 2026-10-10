package com.ksaguide.ksa360

import android.app.Notification
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Intent
import android.os.Build
import android.os.Bundle
import com.google.android.gms.auth.GoogleAuthUtil
import com.google.android.gms.auth.api.signin.GoogleSignIn
import com.google.android.gms.auth.api.signin.GoogleSignInOptions
import com.google.android.gms.common.api.ApiException
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlin.concurrent.thread

class MainActivity : FlutterActivity() {
    private val channelName = "ksa360/google_sign_in"
    private val pushChannelName = "ksa360/push"
    private val requestSignIn = 9173
    private var pending: MethodChannel.Result? = null
    private var lastServerClientId = ""

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        PushChannels.ensure(this)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        PushChannels.ensure(this)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "signIn" -> startSignIn(call.argument<String>("serverClientId").orEmpty(), result)
                    "signOut" -> signOut(call.argument<String>("serverClientId").orEmpty(), result)
                    else -> result.notImplemented()
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, pushChannelName)
            .setMethodCallHandler { call, result ->
                if (call.method == "show") {
                    showPush(
                        call.argument<String>("title").orEmpty(),
                        call.argument<String>("body").orEmpty(),
                    )
                    result.success(true)
                } else {
                    result.notImplemented()
                }
            }
    }

    private fun showPush(title: String, body: String) {
        PushChannels.ensure(this)
        val manager = getSystemService(NotificationManager::class.java) ?: return
        val launch = Intent(this, MainActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        }
        val pending = PendingIntent.getActivity(
            this,
            0,
            launch,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val text = body.ifBlank { title.ifBlank { "KSA 360" } }
        val notification = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, PushChannels.ID)
                .setSmallIcon(R.drawable.ic_stat_ksa)
                .setContentTitle(title.ifBlank { "KSA 360" })
                .setContentText(text)
                .setStyle(Notification.BigTextStyle().bigText(text))
                .setContentIntent(pending)
                .setAutoCancel(true)
                .setVisibility(Notification.VISIBILITY_PUBLIC)
                .setCategory(Notification.CATEGORY_MESSAGE)
                .build()
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
                .setSmallIcon(R.drawable.ic_stat_ksa)
                .setContentTitle(title.ifBlank { "KSA 360" })
                .setContentText(text)
                .setContentIntent(pending)
                .setAutoCancel(true)
                .setPriority(Notification.PRIORITY_HIGH)
                .build()
        }
        manager.notify((System.currentTimeMillis() % Int.MAX_VALUE).toInt(), notification)
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
                        "oauth2:email profile",
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
