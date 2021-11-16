// https://www.geoffchappell.com/studies/windows/win32/kernel32/api/index.htm

//AcquireSRWLockExclusive	6.0 and higher	documented
//AcquireSRWLockShared	6.0 and higher	documented
//AcquireStateLock	6.2 only	 
//ActivateActCtx	5.1 and higher	documented
//ActivateActCtxWorker	6.2 and higher	 
//AddAtomA	3.51 and higher	documented
//AddAtomW	3.51 and higher	documented
//AddConsoleAliasA	3.51 and higher (NT only)	documented
//AddConsoleAliasW	3.51 and higher (NT only)	documented
//AddDllDirectory	6.2 and higher	documented
//AddIntegrityLabelToBoundaryDescriptor	6.1 and higher	 
//AddLocalAlternateComputerNameA	5.1 and higher	documented
//AddLocalAlternateComputerNameW	5.1 and higher	documented
//AddRefActCtx	5.1 and higher	documented
//AddRefActCtxWorker	6.2 and higher	 
//AddResourceAttributeAce	6.2 and higher	documented
//AddSIDToBoundaryDescriptor	6.0 and higher	documented
//AddScopedPolicyIDAce	6.2 and higher	documented
//AddSecureMemoryCacheCallback	6.0 from Windows Vista SP1, and higher	documented
//AddVectoredContinueHandler	5.2 from Windows Server 2003 SP1, and higher	documented
//AddVectoredExceptionHandler	5.1 and higher	documented
//AdjustCalendarDate	6.0 and higher	documented
//AllocConsole	3.51 and higher	documented
//AllocLSCallback	4.0 to 4.90 (Windows only)	 
//AllocMappedBuffer (38)	4.0 to 4.90 (Windows only)	 
//AllocSLCallback	4.0 to 4.90 (Windows only)	 
//AllocateUserPhysicalPages	5.0 and higher	documented
//AllocateUserPhysicalPagesNuma	6.0 and higher	documented
//AppContainerDeriveSidFromMoniker	6.2 only	 
//AppContainerFreeMemory	6.2 only	 
//AppContainerLookupDisplayNameMrtReference	6.2 only	 
//AppContainerLookupMoniker	6.2 only	 
//AppContainerRegisterSid	6.2 only	 
//AppContainerUnregisterSid	6.2 only	 
//AppXFreeMemory	6.2 only	 
//AppXGetApplicationData	6.2 only	 
//AppXGetDevelopmentMode	6.2 only	 
//AppXGetOSMaxVersionTested	6.2 and higher	 
//AppXGetOSMinVersion	6.2 only	 
//AppXGetPackageCapabilities	6.2 only	 
//AppXGetPackageSid	6.2 only	 
//AppXGetPackageState	6.2 only	 
//AppXLookupDisplayName	6.2 only	 
//AppXLookupMoniker	6.2 only	 
//AppXSetPackageState	6.2 only	 
//ApplicationRecoveryFinished	6.0 and higher	documented
//ApplicationRecoveryInProgress	6.0 and higher	documented
//AreFileApisANSI	3.51 and higher	documented
//AssignProcessToJobObject	5.0 and higher	documented
//AttachConsole	5.1 and higher	documented
//BackupRead	3.51 and higher	documented
//BackupSeek	3.51 and higher	documented
//BackupWrite	3.51 and higher	documented
//BaseAttachCompleteThunk	3.51 to 5.0 (NT only)	 
//BaseCheckAppcompatCache	5.1 and higher	 
//BaseCheckAppcompatCacheEx	6.1 and higher	 
//BaseCheckAppcompatCacheExWorker	6.2 and higher	 
//BaseCheckAppcompatCacheWorker	6.2 and higher	 
//BaseCheckElevation	6.2 and higher	 
//BaseCheckRunApp	5.2 from Windows Server 2003 SP1, to 6.3	 
//BaseCleanupAppcompatCache	5.1 only	 
//BaseCleanupAppcompatCacheSupport	5.1 and higher	 
//BaseCleanupAppcompatCacheSupportWorker	6.2 and higher	 
//BaseDestroyVDMEnvironment	6.2 and higher	 
//BaseDllReadWriteIniFile	6.1 and higher	 
//BaseDumpAppcompatCache	5.1 and higher	 
//BaseDumpAppcompatCacheWorker	6.2 and higher	 
//BaseElevationPostProcessing	6.2 and higher	 
//BaseFlushAppcompatCache	5.1 and higher	 
//BaseFlushAppcompatCacheWorker	6.2 and higher	 
//BaseFormatObjectAttributes	6.1 and higher	 
//BaseFormatTimeOut	6.1 and higher	 
//BaseFreeAppCompatDataForProcessWorker	6.3 and higher	 
//BaseGenerateAppCompatData	6.0 and higher	 
//BaseGetNamedObjectDirectory	6.1 and higher	 
//BaseInitAppcompatCache	5.1 only	 
//BaseInitAppcompatCacheSupport	5.1 and higher	 
//BaseInitAppcompatCacheSupportWorker	6.2 and higher	 
//BaseIsAppcompatInfrastructureDisabled	5.2 and higher	 
//BaseIsAppcompatInfrastructureDisabledWorker	6.2 and higher	 
//BaseIsDosApplication	6.2 and higher	 
//BaseProcessInitPostImport	5.1 and 5.2	 
//BaseProcessStart	5.2 only (x64 only)	 
//BaseQueryModuleData	some 5.1 and 5.2, and higher;
//begins in 5.1 from Windows XP SP2;
//begins in 5.2 from Windows Server 2003 SP1	 
//BaseReadAppCompatDataForProcessWorker	6.3 and higher	 
//BaseSetLastNTError	6.1 and higher	 
//BaseThreadInitThunk	6.0 and higher	 
//BaseThreadStart	5.2 only (x64 only)	 
//BaseUpdateAppcompatCache	5.1 and higher	 
//BaseUpdateAppcompatCacheWorker	6.2 and higher	 
//BaseUpdateVDMEntry	6.2 and higher	 
//BaseVerifyUnicodeString	6.1 and higher	 
//BaseWriteErrorElevationRequiredEvent	6.2 and higher	 
//Basep8BitStringToDynamicUnicodeString	6.1 and higher	 
//BasepAllocateActivationContextActivationBlock	6.1 and higher	 
//BasepAnsiStringToDynamicUnicodeString	6.1 and higher	 
//BasepAppCompatHookDLL	6.2 only	 
//BasepAppContainerEnvironmentExtension	6.2 and higher	 
//BasepAppXExtension	6.2 and higher	 
//BasepCheckAppCompat	6.1 and higher	 
//BasepCheckBadapp	5.2 from Windows Server 2003 SP1, to 6.3	 
//BasepCheckWebBladeHashes	6.2 and higher	 
//BasepCheckWinSaferRestrictions	some 5.1 and 5.2, and higher;
//begins in 5.1 from Windows XP SP2;
//begins in 5.2 from Windows Server 2003 SP1	 
//BasepConstructSxsCreateProcessMessage	6.2 and higher	 
//BasepCopyEncryption	6.2 and higher	 
//BasepFreeActivationContextActivationBlock	6.1 and higher	 
//BasepFreeAppCompatData	5.2 from Windows Server 2003 SP1, and higher	 
//BasepGetAppCompatData	6.2 and higher	 
//BasepGetComputerNameFromNtPath	6.2 and higher	 
//BasepGetExeArchType	6.2 and higher	 
//BasepIsProcessAllowed	6.2 and higher	 
//BasepMapModuleHandle	6.1 and higher	 
//BasepNotifyLoadStringResource	6.2 and higher	 
//BasepPostSuccessAppXExtension	6.2 and higher	 
//BasepProcessInvalidImage	6.2 and higher	 
//BasepQueryAppCompat	6.2 and higher	 
//BasepReleaseAppXContext	6.2 and higher	 
//BasepReleaseSxsCreateProcessUtilityStruct	6.2 and higher	 
//BasepReportFault	6.2 and higher	 
//BasepSetFileEncryptionCompression	6.2 and higher	 
//Beep	3.51 and higher	documented
//BeginUpdateResourceA	3.51 and higher	documented
//BeginUpdateResourceW	3.51 and higher	documented
//BindIoCompletionCallback	5.0 and higher	documented
//BoostFileCache (101)	4.0 to 4.90 (Windows only)	 
//BuildCommDCBA	3.51 and higher	documented
//BuildCommDCBAndTimeoutsA	3.51 and higher	documented
//BuildCommDCBAndTimeoutsW	3.51 and higher	documented
//BuildCommDCBW	3.51 and higher	documented
//CallNamedPipeA	3.51 and higher	documented
//CallNamedPipeW	3.51 and higher	documented
//Callback12	4.0 to 4.90 (Windows only)	 
//Callback16	4.0 to 4.90 (Windows only)	 
//Callback20	4.0 to 4.90 (Windows only)	 
//Callback24	4.0 to 4.90 (Windows only)	 
//Callback28	4.0 to 4.90 (Windows only)	 
//Callback32	4.0 to 4.90 (Windows only)	 
//Callback36	4.0 to 4.90 (Windows only)	 
//Callback4	4.0 to 4.90 (Windows only)	 
//Callback40	4.0 to 4.90 (Windows only)	 
//Callback44	4.0 to 4.90 (Windows only)	 
//Callback48	4.0 to 4.90 (Windows only)	 
//Callback52	4.0 to 4.90 (Windows only)	 
//Callback56	4.0 to 4.90 (Windows only)	 
//Callback60	4.0 to 4.90 (Windows only)	 
//Callback64	4.0 to 4.90 (Windows only)	 
//Callback8	4.0 to 4.90 (Windows only)	 
//CallbackMayRunLong	6.0 and higher	documented
//CalloutOnFiberStack	6.3 and higher	 
//CancelDeviceWakeupRequest	4.10 and higher	 
//CancelIo	4.0 from Windows NT 4.0, and higher	documented
//CancelIoEx	6.0 and higher	documented
//CancelSynchronousIo	6.0 and higher	documented
//CancelThreadpoolIo	6.0 and higher	documented
//CancelTimerQueueTimer	5.0 and higher	 
//CancelWaitableTimer	4.0 from Windows NT 4.0, and higher	documented
//CeipIsOptedIn	6.2 and higher	documented
//ChangeTimerQueueTimer	5.0 and higher	documented
//CheckAllowDecryptedRemoteDestinationPolicy	6.2 and higher	 
//CheckElevation	6.0 and higher	 
//CheckElevationEnabled	6.0 and higher	 
//CheckForReadOnlyResource	6.0 and higher	 
//CheckForReadOnlyResourceFilter	6.2 and higher	 
//CheckNameLegalDOS8Dot3A	5.1 from Windows XP SP1, and higher	documented for settlement
//CheckNameLegalDOS8Dot3W	5.1 from Windows XP SP1, and higher	documented for settlement
//CheckRemoteDebuggerPresent	5.1 from Windows XP SP1, and higher	documented
//CheckTokenCapability	6.2 and higher	documented
//CheckTokenMembershipEx	6.2 and higher	documented
//ClearCommBreak	3.51 and higher	documented
//ClearCommError	3.51 and higher	documented
//CloseConsoleHandle	3.51 and higher (NT only)	 
//CloseHandle	3.51 and higher	documented
//ClosePackageInfo	6.2 and higher	documented
//ClosePrivateNamespace	6.0 and higher	documented
//CloseProfileUserMapping	3.51 and higher	 
//CloseState	6.2 and higher	 
//CloseStateAtom	6.2 only	 
//CloseStateChangeNotification	6.2 only	 
//CloseStateContainer	6.2 only	 
//CloseStateLock	6.2 only	 
//CloseSystemHandle	4.0 to 4.90 (Windows only)	 
//CloseThreadpool	6.0 and higher	documented
//CloseThreadpoolCleanupGroup	6.0 and higher	documented
//CloseThreadpoolCleanupGroupMembers	6.0 and higher	documented
//CloseThreadpoolIo	6.0 and higher	documented
//CloseThreadpoolTimer	6.0 and higher	documented
//CloseThreadpoolWait	6.0 and higher	documented
//CloseThreadpoolWork	6.0 and higher	documented
//CmdBatNotification	3.51 and higher (NT only)	 
//CommConfigDialogA	3.51 and higher	documented
//CommConfigDialogW	3.51 and higher	documented
//CommitStateAtom	6.2 only	 
//Common32ThkLS (45)	4.0 to 4.90 (Windows only)	 
//CommonUnimpStub (17)	4.0 to 4.90 (Windows only)	 
//CompareCalendarDates	6.0 and higher	 
//CompareFileTime	3.51 and higher	documented
//CompareStringA	3.51 and higher	documented
//CompareStringEx	6.0 and higher	documented
//CompareStringOrdinal	6.0 and higher	documented
//CompareStringW	3.51 and higher	documented
//ConnectNamedPipe	3.51 and higher	documented
//ConsoleIMERoutine	5.2 and 6.0 (x64 only)	 
//ConsoleMenuControl	3.51 and higher (NT only)	 
//ContinueDebugEvent	3.51 and higher	documented
//ConvertCalDateTimeToSystemTime	6.0 and higher	documented
//ConvertDefaultLocale	3.51 and higher	documented
//ConvertFiberToThread	5.1 and higher	documented
//ConvertNLSDayOfWeekToWin32DayOfWeek	6.0 and higher	 
//ConvertSystemTimeToCalDateTime	6.0 and higher	documented
//ConvertThreadToFiber	3.51 from Windows NT 3.51 SP5, and higher (NT);
//4.10 to 4.90 (Windows)	documented
//ConvertThreadToFiberEx	5.2 and higher	documented
//ConvertToGlobalHandle	4.0 to 4.90 (Windows only)	 
//CopyContext	6.1 from Windows 7 SP1, and higher	documented
//CopyExtendedContext	6.1 before Windows 7 SP1	documented
//CopyFile2	6.2 and higher	documented
//CopyFileA	3.51 and higher	documented
//CopyFileExA	4.0 from Windows NT 4.0, and higher	documented
//CopyFileExW	4.0 from Windows NT 4.0, and higher	documented
//CopyFileTransactedA	6.0 and higher	documented
//CopyFileTransactedW	6.0 and higher	documented
//CopyFileW	3.51 and higher	documented
//CopyLZFile	5.1 and higher	documented
//CreateActCtxA	5.1 and higher	documented
//CreateActCtxW	5.1 and higher	documented
//CreateActCtxWWorker	6.2 and higher	 
//CreateBoundaryDescriptorA	6.0 and higher	documented
//CreateBoundaryDescriptorW	6.0 and higher	documented
//CreateConsoleScreenBuffer	3.51 and higher	documented
//CreateDirectoryA	3.51 and higher	documented
//CreateDirectoryExA	3.51 and higher	documented
//CreateDirectoryExW	3.51 and higher	documented
//CreateDirectoryTransactedA	6.0 and higher	documented
//CreateDirectoryTransactedW	6.0 and higher	documented
//CreateDirectoryW	3.51 and higher	documented
//CreateEventA	3.51 and higher	documented
//CreateEventExA	6.0 and higher	documented
//CreateEventExW	6.0 and higher	documented
//CreateEventW	3.51 and higher	documented
//CreateFiber	3.51 from Windows NT 3.51 SP5, and higher (NT);
//4.10 to 4.90 (Windows)	documented
//CreateFiberEx	5.0 from Windows 2000 SP2, and higher	documented
//CreateFile2	6.2 and higher	documented
//CreateFileA	3.51 and higher	documented
//CreateFileMappingA	3.51 and higher	documented
//CreateFileMappingFromApp	6.2 and higher	documented
//CreateFileMappingNumaA	6.0 and higher	documented
//CreateFileMappingNumaW	6.0 and higher	documented
//CreateFileMappingW	3.51 and higher	documented
//CreateFileTransactedA	6.0 and higher	documented
//CreateFileTransactedW	6.0 and higher	documented
//CreateFileW	3.51 and higher	documented
//CreateHardLinkA	5.0 and higher	documented
//CreateHardLinkTransactedA	6.0 and higher	documented
//CreateHardLinkTransactedW	6.0 and higher	documented
//CreateHardLinkW	5.0 and higher	documented
//CreateIoCompletionPort	3.51 and higher	documented
//CreateJobObjectA	5.0 and higher	documented
//CreateJobObjectW	5.0 and higher	documented
//CreateJobSet	5.1 and higher	 
//CreateKernelThread	4.0 to 4.90 (Windows only)	 
//CreateMailslotA	3.51 and higher	documented
//CreateMailslotW	3.51 and higher	documented
//CreateMemoryResourceNotification	5.1 and higher	documented
//CreateMutexA	3.51 and higher	documented
//CreateMutexExA	6.0 and higher	documented
//CreateMutexExW	6.0 and higher	documented
//CreateMutexW	3.51 and higher	documented
//CreateNamedPipeA	3.51 and higher	documented
//CreateNamedPipeW	3.51 and higher	documented
//CreateNlsSecurityDescriptor	5.1 from Windows XP SP1 to 5.2	 
//CreatePipe	3.51 and higher	documented
//CreatePrivateNamespaceA	6.0 and higher	documented
//CreatePrivateNamespaceW	6.0 and higher	documented
//CreateProcessA	3.51 and higher	documented
//CreateProcessAsUserA	10.0 and higher;
//earlier in ADVAPI32	documented (ADVAPI32)
//CreateProcessAsUserW	6.1 and higher;
//earlier in ADVAPI32	documented (ADVAPI32)
//CreateProcessInternalA	5.0 from Windows 2000 SP3, and higher	 
//CreateProcessInternalW	5.0 from Windows 2000 SP3, and higher	 
//CreateProcessInternalWSecure	some 5.0 and 5.1 only;
//begins in 5.0 from Windows 2000 SP4;
//begins in 5.1 from Windows XP SP2	 
//CreateProcessW	3.51 and higher	documented
//CreateRemoteThread	3.51 and higher	documented
//CreateRemoteThreadEx	6.1 and higher	documented
//CreateSemaphoreA	3.51 and higher	documented
//CreateSemaphoreExA	6.0 and higher	documented
//CreateSemaphoreExW	6.0 and higher	documented
//CreateSemaphoreW	3.51 and higher	documented
//CreateSocketHandle	4.0 to 4.90 (Windows);
//5.1 and higher (NT, x86 only)	 
//CreateStateAtom	6.2 only	 
//CreateStateChangeNotification	6.2 only	 
//CreateStateContainer	6.2 only	 
//CreateStateLock	6.2 only	 
//CreateStateSubcontainer	6.2 only	 
//CreateSymbolicLinkA	6.0 and higher	documented
//CreateSymbolicLinkTransactedA	6.0 and higher	documented
//CreateSymbolicLinkTransactedW	6.0 and higher	documented
//CreateSymbolicLinkW	6.0 and higher	documented
//CreateTapePartition	3.51 and higher	documented
//CreateThread	3.51 and higher	documented
//CreateThreadpool	6.0 and higher	documented
//CreateThreadpoolCleanupGroup	6.0 and higher	documented
//CreateThreadpoolIo	6.0 and higher	documented
//CreateThreadpoolTimer	6.0 and higher	documented
//CreateThreadpoolWait	6.0 and higher	documented
//CreateThreadpoolWork	6.0 and higher	documented
//CreateTimerQueue	5.0 and higher	documented
//CreateTimerQueueTimer	5.0 and higher	documented
//CreateToolhelp32Snapshot	4.0 and higher	documented
//CreateUmsCompletionList	6.1 and higher (x64 only)	documented
//CreateUmsThreadContext	6.1 and higher (x64 only)	documented
//CreateVirtualBuffer	3.51 to 5.2 before Windows Server 2003 SP1 (NT only)	 
//CreateWaitableTimerA	4.0 (NT) and higher	documented
//CreateWaitableTimerExA	6.0 and higher	documented
//CreateWaitableTimerExW	6.0 and higher	documented
//CreateWaitableTimerW	4.0 (NT) and higher	documented
//CtrlRoutine	5.2 from Windows Server 2003 SP1, and higher (x64);
//6.1 and higher (x86)	 
//DeactivateActCtx	5.1 and higher	documented
//DeactivateActCtxWorker	6.2 and higher	 
//DebugActiveProcess	3.51 and higher	documented
//DebugActiveProcessStop	5.1 and higher	documented
//DebugBreak	3.51 and higher	documented
//DebugBreakProcess	5.1 and higher	documented
//DebugSetProcessKillOnExit	5.1 and higher	documented
//DecodePointer	some 5.1 and 5.2, and higher;
//begins in 5.1 from Windows XP SP2;
//begins in 5.2 from Windows Server 2003 SP1	documented
//DecodeSystemPointer	some 5.1 and 5.2, and higher;
//begins in 5.1 from Windows XP SP2;
//begins in 5.2 from Windows Server 2003 SP1	documented
//DefineDosDeviceA	3.51 and higher	documented
//DefineDosDeviceW	3.51 and higher	documented
//DelayLoadFailureHook	5.0 and higher	 
//DeleteAtom	3.51 and higher	documented
//DeleteBoundaryDescriptor	6.0 and higher	documented
//DeleteCriticalSection	3.51 and higher	documented
//DeleteFiber	3.51 from Windows NT 3.51 SP5, and higher (NT);
//4.10 to 4.90 (Windows)	documented
//DeleteFileA	3.51 and higher	documented
//DeleteFileTransactedA	6.0 and higher	documented
//DeleteFileTransactedW	6.0 and higher	documented
//DeleteFileW	3.51 and higher	documented
//DeleteProcThreadAttributeList	6.0 and higher	documented
//DeleteStateAtomValue	6.2 only	 
//DeleteStateContainer	6.2 only	 
//DeleteStateContainerValue	6.2 only	 
//DeleteSynchronizationBarrier	6.3 and higher	documented
//DeleteTimerQueue	5.0 and higher	documented
//DeleteTimerQueueEx	5.0 and higher	documented
//DeleteTimerQueueTimer	5.0 and higher	documented
//DeleteUmsCompletionList	6.1 and higher (x64 only)	documented
//DeleteUmsThreadContext	6.1 and higher (x64 only)	documented
//DeleteVolumeMountPointA	5.0 and higher	documented
//DeleteVolumeMountPointW	5.0 and higher	documented
//DequeueUmsCompletionListItems	6.1 and higher (x64 only)	documented
//DeviceIoControl	3.51 and higher	documented
//DisableThreadLibraryCalls	3.51 and higher	documented
//DisableThreadProfiling	6.1 and higher	documented
//DisassociateCurrentThreadFromCallback	6.0 and higher	documented
//DiscardVirtualMemory	10.0 and higher	documented
//DisconnectNamedPipe	3.51 and higher	documented
//DisposeLZ32Handle (22)	4.0 to 4.90 (Windows only)	 
//DnsHostnameToComputerNameA	5.0 and higher	documented
//DnsHostnameToComputerNameExW	6.3 and higher	 
//DnsHostnameToComputerNameW	5.0 and higher	documented
//DosDateTimeToFileTime	3.51 and higher	documented
//DosFileHandleToWin32Handle (20)	4.0 to 4.90 (Windows only)	 
//DosPathToSessionPathA	5.0 and higher	 
//DosPathToSessionPathW	5.0 and higher	 
//DuplicateConsoleHandle	3.51 and higher (NT only)	 
//DuplicateEncryptionInfoFileExt	6.2 and higher	 
//DuplicateHandle	3.51 and higher	documented
//DuplicateStateContainerHandle	6.2 only	 
//EnableThreadProfiling	6.1 and higher	documented
//EncodePointer	some 5.1 and 5.2, and higher;
//begins in 5.1 from Windows XP SP2;
//begins in 5.2 from Windows Server 2003 SP1	documented
//EncodeSystemPointer	some 5.1 and 5.2, and higher;
//begins in 5.1 from Windows XP SP2;
//begins in 5.2 from Windows Server 2003 SP1	documented
//EndUpdateResourceA	3.51 and higher	documented
//EndUpdateResourceW	3.51 and higher	documented
//EnterCriticalSection	3.51 and higher	documented
//EnterSynchronizationBarrier	6.3 and higher	documented
//EnterUmsSchedulingMode	6.1 and higher (x64 only)	documented
//EnumCalendarInfoA	3.51 and higher	documented
//EnumCalendarInfoExA	4.10 and higher	documented
//EnumCalendarInfoExEx	6.0 and higher	documented
//EnumCalendarInfoExW	4.10 and higher	documented
//EnumCalendarInfoW	3.51 and higher	documented
//EnumDateFormatsA	3.51 and higher	documented
//EnumDateFormatsExA	4.10 and higher	documented
//EnumDateFormatsExEx	6.0 and higher	documented
//EnumDateFormatsExW	4.10 and higher	documented
//EnumDateFormatsW	3.51 and higher	documented
//EnumLanguageGroupLocalesA	4.90 and higher	documented
//EnumLanguageGroupLocalesW	4.90 and higher	documented
//EnumResourceLanguagesA	3.51 and higher	documented
//EnumResourceLanguagesExA	6.0 and higher	documented
//EnumResourceLanguagesExW	6.0 and higher	documented
//EnumResourceLanguagesW	3.51 and higher	documented
//EnumResourceNamesA	3.51 and higher	documented
//EnumResourceNamesExA	6.0 and higher	documented
//EnumResourceNamesExW	6.0 and higher	documented
//EnumResourceNamesW	3.51 and higher	documented
//EnumResourceTypesA	3.51 and higher	documented
//EnumResourceTypesExA	6.0 and higher	documented
//EnumResourceTypesExW	6.0 and higher	documented
//EnumResourceTypesW	3.51 and higher	documented
//EnumSystemCodePagesA	3.51 and higher	documented
//EnumSystemCodePagesW	3.51 and higher	documented
//EnumSystemFirmwareTables	5.2 from Windows Server 2003 SP1, and higher	documented
//EnumSystemGeoID	4.90 only (Windows);
//5.1 and higher (NT)	documented
//EnumSystemLanguageGroupsA	4.90 and higher	documented
//EnumSystemLanguageGroupsW	4.90 and higher	documented
//EnumSystemLocalesA	3.51 and higher	documented
//EnumSystemLocalesEx	6.0 and higher	documented
//EnumSystemLocalesW	3.51 and higher	documented
//EnumTimeFormatsA	3.51 and higher	documented
//EnumTimeFormatsEx	6.0 and higher	documented
//EnumTimeFormatsW	3.51 and higher	documented
//EnumUILanguagesA	4.90 and higher	documented
//EnumUILanguagesW	4.90 and higher	documented
//EnumerateLocalComputerNamesA	5.1 and higher	 
//EnumerateLocalComputerNamesW	5.1 and higher	 
//EnumerateStateAtomValues	6.2 only	 
//EnumerateStateContainerItems	6.2 only	 
//EraseTape	3.51 and higher	documented
//EscapeCommFunction	3.51 and higher	documented
//ExecuteUmsThread	6.1 and higher (x64 only)	documented
//ExitProcess	3.51 and higher	documented
//ExitThread	3.51 and higher	documented
//ExitVDM	3.51 and higher (NT only)	 
//ExpandEnvironmentStringsA	3.51 and higher	documented
//ExpandEnvironmentStringsW	3.51 and higher	documented
//ExpungeConsoleCommandHistoryA	3.51 and higher (NT only)	 
//ExpungeConsoleCommandHistoryW	3.51 and higher (NT only)	 
//ExtendVirtualBuffer	3.51 to 5.2 before Windows Server 2003 SP1 (NT only)	 
//FT_Exit0	4.0 to 4.90 (Windows only)	 
//FT_Exit12	4.0 to 4.90 (Windows only)	 
//FT_Exit16	4.0 to 4.90 (Windows only)	 
//FT_Exit20	4.0 to 4.90 (Windows only)	 
//FT_Exit24	4.0 to 4.90 (Windows only)	 
//FT_Exit28	4.0 to 4.90 (Windows only)	 
//FT_Exit32	4.0 to 4.90 (Windows only)	 
//FT_Exit36	4.0 to 4.90 (Windows only)	 
//FT_Exit4	4.0 to 4.90 (Windows only)	 
//FT_Exit40	4.0 to 4.90 (Windows only)	 
//FT_Exit44	4.0 to 4.90 (Windows only)	 
//FT_Exit48	4.0 to 4.90 (Windows only)	 
//FT_Exit52	4.0 to 4.90 (Windows only)	 
//FT_Exit56	4.0 to 4.90 (Windows only)	 
//FT_Exit8	4.0 to 4.90 (Windows only)	 
//FT_Prolog	4.0 to 4.90 (Windows only)	 
//FT_PrologPrime (89)	4.0 to 4.90 (Windows only)	 
//FT_Thunk	4.0 to 4.90 (Windows only)	 
//FatalAppExitA	3.51 and higher	documented
//FatalAppExitW	3.51 and higher	documented
//FatalExit	3.51 and higher	documented
//FileTimeToDosDateTime	3.51 and higher	documented
//FileTimeToLocalFileTime	3.51 and higher	documented
//FileTimeToSystemTime	3.51 and higher	documented
//FillConsoleOutputAttribute	3.51 and higher	documented
//FillConsoleOutputCharacterA	3.51 and higher	documented
//FillConsoleOutputCharacterW	3.51 and higher	documented
//FindActCtxSectionGuid	5.1 and higher	documented
//FindActCtxSectionGuidWorker	6.2 and higher	 
//FindActCtxSectionStringA	5.1 and higher	documented
//FindActCtxSectionStringW	5.1 and higher	documented
//FindActCtxSectionStringWWorker	6.2 and higher	 
//FindAtomA	3.51 and higher	documented
//FindAtomW	3.51 and higher	documented
//FindClose	3.51 and higher	documented
//FindCloseChangeNotification	3.51 and higher	documented
//FindFirstChangeNotificationA	3.51 and higher	documented
//FindFirstChangeNotificationW	3.51 and higher	documented
//FindFirstFileA	3.51 and higher	documented
//FindFirstFileExA	4.0 from Windows NT 4.0, and higher	documented
//FindFirstFileExW	4.0 from Windows NT 4.0, and higher	documented
//FindFirstFileNameTransactedW	6.0 and higher	documented
//FindFirstFileNameW	6.0 and higher	documented
//FindFirstFileTransactedA	6.0 and higher	documented
//FindFirstFileTransactedW	6.0 and higher	documented
//FindFirstFileW	3.51 and higher	documented
//FindFirstStreamTransactedW	6.0 and higher	documented
//FindFirstStreamW	5.2 and higher	documented
//FindFirstVolumeA	5.0 and higher	documented
//FindFirstVolumeMountPointA	5.0 and higher	documented
//FindFirstVolumeMountPointW	5.0 and higher	documented
//FindFirstVolumeW	5.0 and higher	documented
//FindNLSString	6.0 and higher	documented
//FindNLSStringEx	6.0 and higher	documented
//FindNextChangeNotification	3.51 and higher	documented
//FindNextFileA	3.51 and higher	documented
//FindNextFileNameW	6.0 and higher	documented
//FindNextFileW	3.51 and higher	documented
//FindNextStreamW	5.2 and higher	documented
//FindNextVolumeA	5.0 and higher	documented
//FindNextVolumeMountPointA	5.0 and higher	documented
//FindNextVolumeMountPointW	5.0 and higher	documented
//FindNextVolumeW	5.0 and higher	documented
//FindPackagesByPackageFamily	6.3 and higher	documented
//FindResourceA	3.51 and higher	documented
//FindResourceExA	3.51 and higher	documented
//FindResourceExW	3.51 and higher	documented
//FindResourceW	3.51 and higher	documented
//FindStringOrdinal	6.1 and higher	documented
//FindVolumeClose	5.0 and higher	documented
//FindVolumeMountPointClose	5.0 and higher	documented
//FlsAlloc	5.2 and higher	documented
//FlsFree	5.2 and higher	documented
//FlsGetValue	5.2 and higher	documented
//FlsSetValue	5.2 and higher	documented
//FlushConsoleInputBuffer	3.51 and higher	documented
//FlushFileBuffers	3.51 and higher	documented
//FlushInstructionCache	3.51 and higher	documented
//FlushProcessWriteBuffers	6.0 and higher	documented
//FlushViewOfFile	3.51 and higher	documented
//FoldStringA	3.51 and higher	documented
//FoldStringW	3.51 and higher	documented
//FormatApplicationUserModelId	6.3 and higher	documented
//FormatMessageA	3.51 and higher	documented
//FormatMessageW	3.51 and higher	documented
//FreeConsole	3.51 and higher	documented
//FreeEnvironmentStringsA	3.51 and higher	documented
//FreeEnvironmentStringsW	3.51 and higher	documented
//FreeLSCallback	4.0 to 4.90 (Windows only)	 
//FreeLibrary	3.51 and higher	documented
//FreeLibrary16 (36)	4.0 to 4.90 (Windows only)	 
//FreeLibraryAndExitThread	3.51 and higher	documented
//FreeLibraryWhenCallbackReturns	6.0 and higher	documented
//FreeMappedBuffer (39)	4.0 to 4.90 (Windows only)	 
//FreeMemoryJobObject	10.0 and higher	documented
//FreeResource	3.51 and higher	documented for settlement
//FreeSLCallback	4.0 to 4.90 (Windows only)	 
//FreeUserPhysicalPages	5.0 and higher	documented
//FreeVirtualBuffer	3.51 to 5.2 before Windows Server 2003 SP1 (NT only)	 
//GDIReallyCares (23)	4.0 to 4.90 (Windows only)	 
//GenerateConsoleCtrlEvent	3.51 and higher	documented
//GetACP	3.51 and higher	documented
//GetActiveProcessorCount	6.1 and higher	documented
//GetActiveProcessorGroupCount	6.1 and higher	documented
//GetAppContainerAce	6.2 and higher	 
//GetAppContainerNamedObjectPath	6.2 and higher	documented
//GetApplicationRecoveryCallback	6.0 and higher	documented
//GetApplicationRecoveryCallbackWorker	6.2 and higher	 
//GetApplicationRestartSettings	6.0 and higher	documented
//GetApplicationRestartSettingsWorker	6.2 and higher	 
//GetApplicationUserModelId	6.2 and higher	documented
//GetAtomNameA	3.51 and higher	documented
//GetAtomNameW	3.51 and higher	documented
//GetBinaryType	3.51 and higher	documented
//GetBinaryTypeA	3.51 and higher	documented
//GetBinaryTypeW	3.51 and higher	documented
//GetCPFileNameFromRegistry	5.1 from Windows XP SP1, to 6.0	 
//GetCPInfo	3.51 and higher	documented
//GetCPInfoExA	4.10 and higher	documented
//GetCPInfoExW	4.10 and higher	documented
//GetCachedSigningLevel	6.2 and higher	 
//GetCalendarDateFormat	6.0 and higher	 
//GetCalendarDateFormatEx	6.0 and higher	documented
//GetCalendarDaysInMonth	6.0 and higher	 
//GetCalendarDifferenceInDays	6.0 and higher	 
//GetCalendarInfoA	4.10 and higher	documented
//GetCalendarInfoEx	6.0 and higher	documented
//GetCalendarInfoW	4.10 and higher	documented
//GetCalendarMonthsInYear	6.0 and higher	 
//GetCalendarSupportedDateRange	6.0 and higher	documented
//GetCalendarWeekNumber	6.0 and higher	 
//GetComPlusPackageInstallStatus	5.1 and higher	documented
//GetCommConfig	3.51 and higher	documented
//GetCommMask	3.51 and higher	documented
//GetCommModemStatus	3.51 and higher	documented
//GetCommProperties	3.51 and higher	documented
//GetCommState	3.51 and higher	documented
//GetCommTimeouts	3.51 and higher	documented
//GetCommandLineA	3.51 and higher	documented
//GetCommandLineW	3.51 and higher	documented
//GetCompressedFileSizeA	3.51 and higher	documented
//GetCompressedFileSizeTransactedA	6.0 and higher	documented
//GetCompressedFileSizeTransactedW	6.0 and higher	documented
//GetCompressedFileSizeW	3.51 and higher	documented
//GetComputerNameA	3.51 and higher	documented
//GetComputerNameExA	5.0 and higher	documented
//GetComputerNameExW	5.0 and higher	documented
//GetComputerNameW	3.51 and higher	documented
//GetConsoleAliasA	3.51 and higher (NT only)	documented
//GetConsoleAliasExesA	3.51 and higher (NT only)	documented
//GetConsoleAliasExesLengthA	3.51 and higher (NT only)	documented
//GetConsoleAliasExesLengthW	3.51 and higher (NT only)	documented
//GetConsoleAliasExesW	3.51 and higher (NT only)	documented
//GetConsoleAliasW	3.51 and higher (NT only)	documented
//GetConsoleAliasesA	3.51 and higher (NT only)	documented
//GetConsoleAliasesLengthA	3.51 and higher (NT only)	documented
//GetConsoleAliasesLengthW	3.51 and higher (NT only)	documented
//GetConsoleAliasesW	3.51 and higher (NT only)	documented
//GetConsoleCP	3.51 and higher	documented
//GetConsoleCharType	5.0 and higher	 
//GetConsoleCommandHistoryA	3.51 and higher (NT only)	 
//GetConsoleCommandHistoryLengthA	3.51 and higher (NT only)	 
//GetConsoleCommandHistoryLengthW	3.51 and higher (NT only)	 
//GetConsoleCommandHistoryW	3.51 and higher (NT only)	 
//GetConsoleCursorInfo	3.51 and higher	documented
//GetConsoleCursorMode	5.0 and higher	 
//GetConsoleDisplayMode	3.51 and higher (NT only)	documented
//GetConsoleFontInfo	3.51 and higher (NT only)	 
//GetConsoleFontSize	3.51 and higher (NT only)	documented
//GetConsoleHardwareState	3.51 and higher (NT only)	 
//GetConsoleHistoryInfo	6.0 and higher	documented
//GetConsoleInputExeNameA	4.0 and higher (NT only)	 
//GetConsoleInputExeNameW	4.0 and higher (NT only)	 
//GetConsoleInputWaitHandle	3.51 and higher (NT only)	 
//GetConsoleKeyboardLayoutNameA	4.0 and higher (NT only)	 
//GetConsoleKeyboardLayoutNameW	4.0 and higher (NT only)	 
//GetConsoleMode	3.51 and higher	documented
//GetConsoleNlsMode	5.0 and higher	 
//GetConsoleOriginalTitleA	6.0 and higher	documented
//GetConsoleOriginalTitleW	6.0 and higher	documented
//GetConsoleOutputCP	3.51 and higher	documented
//GetConsoleProcessList	5.1 and higher	documented
//GetConsoleScreenBufferInfo	3.51 and higher	documented
//GetConsoleScreenBufferInfoEx	6.0 and higher	documented
//GetConsoleSelectionInfo	5.1 and higher	documented
//GetConsoleTitleA	3.51 and higher	documented
//GetConsoleTitleW	3.51 and higher	documented
//GetConsoleWindow	5.0 and higher	documented
//GetCryptApiExponentValue (120)	4.10 to 4.90 (Windows only)	 
//GetCurrencyFormatA	3.51 and higher	documented
//GetCurrencyFormatEx	6.0 and higher	documented
//GetCurrencyFormatW	3.51 and higher	documented
//GetCurrentActCtx	5.1 and higher	documented
//GetCurrentActCtxWorker	6.2 and higher	 
//GetCurrentApplicationUserModelId	6.2 and higher	documented
//GetCurrentConsoleFont	3.51 and higher (NT only)	documented
//GetCurrentConsoleFontEx	6.0 and higher	documented
//GetCurrentDirectoryA	3.51 and higher	documented
//GetCurrentDirectoryW	3.51 and higher	documented
//GetCurrentPackageFamilyName	6.2 and higher	documented
//GetCurrentPackageFullName	6.2 and higher	documented
//GetCurrentPackageId	6.2 and higher	documented
//GetCurrentPackageInfo	6.2 and higher	documented
//GetCurrentPackagePath	6.2 and higher	documented
//GetCurrentProcess	3.51 and higher	documented
//GetCurrentProcessId	3.51 and higher	documented
//GetCurrentProcessorNumber	5.2 and higher	documented
//GetCurrentProcessorNumberEx	6.1 and higher	documented
//GetCurrentThread	3.51 and higher	documented
//GetCurrentThreadId	3.51 and higher	documented
//GetCurrentThreadStackLimits	6.2 and higher	documented
//GetCurrentUmsThread	6.1 and higher (x64 only)	documented
//GetDateFormatA	3.51 and higher	documented
//GetDateFormatAWorker	6.2 and higher	 
//GetDateFormatEx	6.0 and higher	documented
//GetDateFormatW	3.51 and higher	documented
//GetDateFormatWWorker	6.2 and higher	 
//GetDaylightFlag	4.0 to 4.90 (Windows only)	 
//GetDefaultCommConfigA	3.51 and higher	documented
//GetDefaultCommConfigW	3.51 and higher	documented
//GetDefaultSortKeySize	5.0 to 5.2	 
//GetDevicePowerState	4.10 and higher	documented
//GetDiskFreeSpaceA	3.51 and higher	documented
//GetDiskFreeSpaceExA	4.0 from Windows 95 OSR2, and higher	documented
//GetDiskFreeSpaceExW	4.0 from Windows 95 OSR2, and higher	documented
//GetDiskFreeSpaceW	3.51 and higher	documented
//GetDllDirectoryA	5.1 from Windows XP SP1, and higher	documented
//GetDllDirectoryW	5.1 from Windows XP SP1, and higher	documented
//GetDriveTypeA	3.51 and higher	documented
//GetDriveTypeW	3.51 and higher	documented
//GetDurationFormat	6.0 and higher	documented
//GetDurationFormatEx	6.0 and higher	documented
//GetDynamicTimeZoneInformation	6.0 and higher	documented
//GetEnabledExtendedFeatures	6.1 before Windows 7 SP1	documented
//GetEnabledXStateFeatures	6.1 from Windows 7 SP1, and higher	documented
//GetEncryptedFileVersionExt	6.3 and higher	 
//GetEnvironmentStrings	3.51 and higher	documented
//GetEnvironmentStringsA	3.51 and higher	documented
//GetEnvironmentStringsW	3.51 and higher	documented
//GetEnvironmentVariableA	3.51 and higher	documented
//GetEnvironmentVariableW	3.51 and higher	documented
//GetEraNameCountedString	6.1 and higher	 
//GetErrorMode	4.0 to 4.90 (Windows);
//6.0 and higher (NT)	documented
//GetExitCodeProcess	3.51 and higher	documented
//GetExitCodeThread	3.51 and higher	documented
//GetExpandedNameA	5.1 and higher	documented
//GetExpandedNameW	5.1 and higher	documented
//GetExtendedContextLength	6.1 before Windows 7 SP1	documented
//GetExtendedFeaturesMask	6.1 before Windows 7 SP1	documented
//GetFileAttributesA	3.51 and higher	documented
//GetFileAttributesExA	4.0 from Windows NT 4.0, and higher	documented
//GetFileAttributesExW	4.0 from Windows NT 4.0, and higher	documented
//GetFileAttributesTransactedA	6.0 and higher	documented
//GetFileAttributesTransactedW	6.0 and higher	documented
//GetFileAttributesW	3.51 and higher	documented
//GetFileBandwidthReservation	6.0 and higher	documented
//GetFileInformationByHandle	3.51 and higher	documented
//GetFileInformationByHandleEx	6.0 and higher	documented
//GetFileMUIInfo	6.0 and higher	documented
//GetFileMUIPath	6.0 and higher	documented
//GetFileSize	3.51 and higher	documented
//GetFileSizeEx	5.0 and higher	documented
//GetFileTime	3.51 and higher	documented
//GetFileType	3.51 and higher	documented
//GetFinalPathNameByHandleA	6.0 and higher	documented
//GetFinalPathNameByHandleW	6.0 and higher	documented
//GetFirmwareEnvironmentVariableA	5.1 and higher	documented
//GetFirmwareEnvironmentVariableExA	6.2 and higher	documented
//GetFirmwareEnvironmentVariableExW	6.2 and higher	documented
//GetFirmwareEnvironmentVariableW	5.1 and higher	documented
//GetFirmwareType	6.2 and higher	documented
//GetFullPathNameA	3.51 and higher	documented
//GetFullPathNameTransactedA	6.0 and higher	documented
//GetFullPathNameTransactedW	6.0 and higher	documented
//GetFullPathNameW	3.51 and higher	documented
//GetGeoInfoA	4.90 only (Windows);
//5.1 and higher (NT)	documented
//GetGeoInfoW	4.90 only (Windows);
//5.1 and higher (NT)	documented
//GetHandleContext	4.0 to 4.90 (Windows);
//5.1 and higher (NT, x86 only)	 
//GetHandleInformation	3.51 and higher	documented
//GetHivePath	6.2 only	 
//GetLSCallbackTarget	4.0 to 4.90 (Windows only)	 
//GetLSCallbackTemplate	4.0 to 4.90 (Windows only)	 
//GetLargePageMinimum	5.2 and higher	documented
//GetLargestConsoleWindowSize	3.51 and higher	documented
//GetLastError	3.51 and higher	documented
//GetLinguistLangSize	5.0 to 5.2	 
//GetLocalTime	3.51 and higher	documented
//GetLocaleInfoA	3.51 and higher	documented
//GetLocaleInfoEx	6.0 and higher	documented
//GetLocaleInfoW	3.51 and higher	documented
//GetLogicalDriveStringsA	3.51 and higher	documented
//GetLogicalDriveStringsW	3.51 and higher	documented
//GetLogicalDrives	3.51 and higher	documented
//GetLogicalProcessorInformation	5.1 from Windows XP SP3, and higher	documented
//GetLogicalProcessorInformationEx	6.1 and higher	documented
//GetLongPathNameA	4.10 and higher	documented
//GetLongPathNameTransactedA	6.0 and higher	documented
//GetLongPathNameTransactedW	6.0 and higher	documented
//GetLongPathNameW	4.10 and higher	documented
//GetMailslotInfo	3.51 and higher	documented
//GetMaximumProcessorCount	6.1 and higher	documented
//GetMaximumProcessorGroupCount	6.1 and higher	documented
//GetMemoryErrorHandlingCapabilities	6.2 and higher	documented
GetModuleFileNameA :: (hModule : HMODULE, lpFilename : *CHAR,  nSize : DWORD) -> DWORD #foreign kernel32;
GetModuleFileNameW :: (hModule : HMODULE, lpFilename : *WCHAR, nSize : DWORD) -> DWORD #foreign kernel32;
#if UNICODE GetModuleFileName :: GetModuleFileNameW;
else        GetModuleFileName :: GetModuleFileNameA;
GetModuleHandleA   :: (lpModuleName : *CHAR)  -> HMODULE #foreign kernel32;
GetModuleHandleW   :: (lpModuleName : *WCHAR) -> HMODULE #foreign kernel32;
GetModuleHandleExA :: (dwFlags : DWORD, lpModuleName : *CHAR,  phModule : *HMODULE) -> BOOL #foreign kernel32;
GetModuleHandleExW :: (dwFlags : DWORD, lpModuleName : *WCHAR, phModule : *HMODULE) -> BOOL #foreign kernel32;
#if UNICODE GetModuleHandle   :: GetModuleHandleW;
else        GetModuleHandle   :: GetModuleHandleA;
#if UNICODE GetModuleHandleEx :: GetModuleHandleExW;
else        GetModuleHandleEx :: GetModuleHandleExA;
//GetNLSVersion	5.2 and higher	documented
//GetNLSVersionEx	6.0 and higher	documented
//GetNamedPipeAttribute	6.0 and higher	 
//GetNamedPipeClientComputerNameA	6.0 and higher	documented
//GetNamedPipeClientComputerNameW	6.0 and higher	documented
//GetNamedPipeClientProcessId	6.0 and higher	documented
//GetNamedPipeClientSessionId	6.0 and higher	documented
//GetNamedPipeHandleStateA	3.51 and higher	documented
//GetNamedPipeHandleStateW	3.51 and higher	documented
//GetNamedPipeInfo	3.51 and higher	documented
//GetNamedPipeServerProcessId	6.0 and higher	documented
//GetNamedPipeServerSessionId	6.0 and higher	documented
//GetNativeSystemInfo	5.1 and higher	documented
//GetNextUmsListItem	6.1 and higher (x64 only)	documented
//GetNextVDMCommand	3.51 and higher (NT only)	 
//GetNlsSectionName	5.0 to 5.2	 
//GetNumaAvailableMemory	5.1 only	 
//GetNumaAvailableMemoryNode	5.1 and higher	documented
//GetNumaAvailableMemoryNodeEx	6.1 and higher	documented
//GetNumaHighestNodeNumber	5.1 and higher	documented
//GetNumaNodeNumberFromHandle	6.1 and higher	documented
//GetNumaNodeProcessorMask	5.1 and higher	documented
//GetNumaNodeProcessorMaskEx	6.1 and higher	documented
//GetNumaProcessorMap	5.1 only	 
//GetNumaProcessorNode	5.1 and higher	documented
//GetNumaProcessorNodeEx	6.1 and higher	documented
//GetNumaProximityNode	6.0 and higher	documented
//GetNumaProximityNodeEx	6.1 and higher	documented
//GetNumberFormatA	3.51 and higher	documented
//GetNumberFormatEx	6.0 and higher	documented
//GetNumberFormatW	3.51 and higher	documented
//GetNumberOfConsoleFonts	3.51 and higher (NT only)	 
//GetNumberOfConsoleInputEvents	3.51 and higher	documented
//GetNumberOfConsoleMouseButtons	3.51 and higher	documented
//GetOEMCP	3.51 and higher	documented
//GetOverlappedResult	3.51 and higher	documented
//GetOverlappedResultEx	6.2 and higher	documented
//GetPK16SysVar (92)	4.0 to 4.90 (Windows only)	 
//GetPackageApplicationIds	6.3 and higher	documented
//GetPackageFamilyName	6.2 and higher	documented
//GetPackageFullName	6.2 and higher	documented
//GetPackageId	6.2 and higher	documented
//GetPackageInfo	6.2 and higher	documented
//GetPackagePath	6.2 and higher	documented
//GetPackagePathByFullName	6.3 and higher	documented
//GetPackagesByPackageFamily	6.2 and higher	documented
//GetPhysicallyInstalledSystemMemory	6.0 from Windows Vista SP1, and higher	documented
//GetPriorityClass	3.51 and higher	documented
//GetPrivateProfileIntA	3.51 and higher	documented
//GetPrivateProfileIntW	3.51 and higher	documented
//GetPrivateProfileSectionA	3.51 and higher	documented
//GetPrivateProfileSectionNamesA	3.51 and higher	documented
//GetPrivateProfileSectionNamesW	3.51 and higher	documented
//GetPrivateProfileSectionW	3.51 and higher	documented
//GetPrivateProfileStringA	3.51 and higher	documented
//GetPrivateProfileStringW	3.51 and higher	documented
//GetPrivateProfileStructA	3.51 and higher	documented
//GetPrivateProfileStructW	3.51 and higher	documented
GetProcAddress :: (hModule : HMODULE, lpProcName : *CHAR) -> *void #foreign kernel32;
//GetProcessAffinityMask	3.51 and higher	documented
//GetProcessDEPPolicy	some 5.1 and 6.0, and higher;
//begins in 5.1 from Windows XP SP3;
//begins in 6.0 from Windows Vista SP1	documented
//GetProcessDefaultCpuSets	10.0 and higher	documented
//GetProcessGroupAffinity	6.1 and higher	documented
GetProcessHandleCount :: (hProcess : HANDLE, pdwHandleCount : *DWORD) -> BOOL #foreign kernel32;
GetProcessHeap  :: () -> HANDLE #foreign kernel32;
GetProcessHeaps	:: (NumberOfHeaps : DWORD, ProcessHeaps : *HANDLE) -> DWORD #foreign kernel32;
//GetProcessId	5.1 from Windows XP SP1, and higher	documented
//GetProcessIdOfThread	5.2 and higher	documented
//GetProcessInformation	6.2 and higher	documented
//GetProcessIoCounters	5.0 and higher	documented
//GetProcessMitigationPolicy	6.2 and higher	documented
//GetProcessPreferredUILanguages	6.1 and higher	documented
//GetProcessPriorityBoost	4.0 from Windows NT 4.0, and higher	documented
//GetProcessShutdownParameters	3.51 and higher	documented
//GetProcessTimes	3.51 and higher	documented
//GetProcessUserModeExceptionPolicy	6.1 from Windows 7 SP1 only	 
//GetProcessVersion	3.51 and higher	documented
//GetProcessWorkingSetSize	3.51 and higher	documented
//GetProcessWorkingSetSizeEx	5.2 and higher	documented
//GetProcessorSystemCycleTime	6.1 and higher	documented
//GetProductInfo	6.0 and higher	documented
//GetProductName	4.0 to 4.90 (Windows only)	 
//GetProfileIntA	3.51 and higher	documented
//GetProfileIntW	3.51 and higher	documented
//GetProfileSectionA	3.51 and higher	documented
//GetProfileSectionW	3.51 and higher	documented
//GetProfileStringA	3.51 and higher	documented
//GetProfileStringW	3.51 and higher	documented
//GetQueuedCompletionStatus	3.51 and higher	documented
//GetQueuedCompletionStatusEx	6.0 and higher	documented
//GetRoamingLastObservedChangeTime	6.2 only	 
//GetSLCallbackTarget	4.0 to 4.90 (Windows only)	 
//GetSLCallbackTemplate	4.0 to 4.90 (Windows only)	 
//GetSerializedAtomBytes	6.2 only	 
//GetShortPathNameA	3.51 and higher	documented
//GetShortPathNameW	3.51 and higher	documented
//GetStagedPackagePathByFullName	6.3 and higher	documented
//GetStartupInfoA	3.51 and higher	documented
//GetStartupInfoW	3.51 and higher	documented
//GetStateContainerDepth	6.2 only	 
//GetStateFolder	6.2 and higher	 
//GetStateRootFolder	6.2 only	 
//GetStateSettingsFolder	6.2 only	 
//GetStateVersion	6.2 only	 
//GetStdHandle	3.51 and higher	documented
//GetStringScripts	6.0 and higher	documented
//GetStringTypeA	3.51 and higher	documented
//GetStringTypeExA	3.51 and higher	documented
//GetStringTypeExW	3.51 and higher	documented
//GetStringTypeW	3.51 and higher	documented
//GetSystemAppDataFolder	6.2 only	 
//GetSystemAppDataKey	6.2 and higher	 
//GetSystemCpuSetInformation	10.0 and higher	documented
//GetSystemDEPPolicy	some 5.1 and 6.0, and higher;
//begins in 5.1 from Windows XP SP3;
//begins in 6.0 from Windows Vista SP1	documented
//GetSystemDefaultLCID	3.51 and higher	documented
//GetSystemDefaultLangID	3.51 and higher	documented
//GetSystemDefaultLocaleName	6.0 and higher	documented
//GetSystemDefaultUILanguage	4.90 and higher	documented
//GetSystemDirectoryA	3.51 and higher	documented
//GetSystemDirectoryW	3.51 and higher	documented
//GetSystemFileCacheSize	5.2 from Windows Server 2003 SP1, and higher	documented
//GetSystemFirmwareTable	5.2 from Windows Server 2003 SP1, and higher	documented
//GetSystemInfo	3.51 and higher	documented
//GetSystemPowerStatus	3.51 and higher	documented
//GetSystemPreferredUILanguages	6.0 and higher	documented
//GetSystemRegistryQuota	5.1 from Windows XP SP1, and higher	documented
//GetSystemTime	3.51 and higher	documented
//GetSystemTimeAdjustment	3.51 and higher	documented
//GetSystemTimeAsFileTime	3.51 and higher	documented
//GetSystemTimePreciseAsFileTime	6.2 and higher	documented
//GetSystemTimes	5.1 from Windows XP SP1, and higher	documented
//GetSystemWindowsDirectoryA	5.0 and higher	documented
//GetSystemWindowsDirectoryW	5.0 and higher	documented
//GetSystemWow64DirectoryA	5.1 and higher	documented
//GetSystemWow64DirectoryW	5.1 and higher	documented
//GetTapeParameters	3.51 and higher	documented
//GetTapePosition	3.51 and higher	documented
//GetTapeStatus	3.51 and higher	documented
//GetTempFileNameA	3.51 and higher	documented
//GetTempFileNameW	3.51 and higher	documented
//GetTempPathA	3.51 and higher	documented
//GetTempPathW	3.51 and higher	documented
//GetThreadContext	3.51 and higher	documented
//GetThreadErrorMode	6.1 and higher	documented
//GetThreadGroupAffinity	6.1 and higher	documented
//GetThreadIOPendingFlag	5.1 from Windows XP SP1, and higher	documented
//GetThreadId	5.2 and higher	documented
//GetThreadIdealProcessorEx	6.1 and higher	documented
//GetThreadInformation	6.2 and higher	documented
//GetThreadLocale	3.51 and higher	documented
//GetThreadPreferredUILanguages	6.0 and higher	documented
//GetThreadPriority	3.51 and higher	documented
//GetThreadPriorityBoost	4.0 from Windows NT 4.0, and higher	documented
//GetThreadSelectedCpuSets	10.0 and higher	documented
//GetThreadSelectorEntry	3.51 and higher	documented
//GetThreadTimes	3.51 and higher	documented
//GetThreadUILanguage	6.0 and higher	documented
//GetThunkBuff (52)	4.0 to 4.90 (Windows only)	 
//GetThunkStuff (53)	4.0 to 4.90 (Windows only)	 
GetTickCount   :: () -> ULONG     #foreign kernel32;
GetTickCount64 :: () -> ULONGLONG #foreign kernel32;
//GetTimeFormatA	3.51 and higher	documented
//GetTimeFormatAWorker	6.2 and higher	 
//GetTimeFormatEx	6.0 and higher	documented
//GetTimeFormatW	3.51 and higher	documented
//GetTimeFormatWWorker	6.2 and higher	 
//GetTimeZoneInformation	3.51 and higher	documented
//GetTimeZoneInformationForYear	6.0 from Windows Vista SP1, and higher	documented
//GetUILanguageInfo	6.0 and higher	documented
//GetUmsCompletionListEvent	6.1 and higher (x64 only)	documented
//GetUmsSystemThreadInformation	6.1 from Windows 7 SP1, and higher (x64 only)	documented
//GetUserDefaultLCID	3.51 and higher	documented
//GetUserDefaultLangID	3.51 and higher	documented
//GetUserDefaultLocaleName	6.0 and higher	documented
//GetUserDefaultUILanguage	4.90 and higher	documented
//GetUserGeoID	4.90 only (Windows);
//5.1 and higher (NT)	documented
//GetUserPreferredUILanguages	6.0 and higher	documented
//GetVDMCurrentDirectories	3.51 and higher (NT only)	 
//GetVersion	3.51 and higher	documented
//GetVersionExA	3.51 and higher	documented
//GetVersionExW	3.51 and higher	documented
//GetVolumeInformationA	3.51 and higher	documented
//GetVolumeInformationByHandleW	6.0 and higher	documented
//GetVolumeInformationW	3.51 and higher	documented
//GetVolumeNameForVolumeMountPointA	5.0 and higher	documented
//GetVolumeNameForVolumeMountPointW	5.0 and higher	documented
//GetVolumePathNameA	5.0 and higher	documented
//GetVolumePathNameW	5.0 and higher	documented
//GetVolumePathNamesForVolumeNameA	5.1 and higher	documented
//GetVolumePathNamesForVolumeNameW	5.1 and higher	documented
//GetWin16DOSEnv (34)	4.0 to 4.90 (Windows only)	 
//GetWindowsDirectoryA	3.51 and higher	documented
//GetWindowsDirectoryW	3.51 and higher	documented
//GetWriteWatch	4.10 and higher	documented
//GetXStateFeaturesMask	6.1 from Windows 7 SP1, and higher	documented
//GetpWin16Lock (93)	4.0 to 4.90 (Windows only)	 
//GlobalAddAtomA	3.51 and higher	documented
//GlobalAddAtomExA	6.2 and higher	documented
//GlobalAddAtomExW	6.2 and higher	documented
//GlobalAddAtomW	3.51 and higher	documented
//GlobalAlloc16 (24)	4.0 to 4.90 (Windows only)	 
//GlobalCompact	3.51 and higher	documented
//GlobalDeleteAtom	3.51 and higher	documented
//GlobalFindAtomA	3.51 and higher	documented
//GlobalFindAtomW	3.51 and higher	documented
//GlobalFix	3.51 and higher	documented
//GlobalFix16 (27)	4.0 to 4.90 (Windows only)	 
//GlobalFlags	3.51 and higher	documented
//GlobalFree16 (31)	4.0 to 4.90 (Windows only)	 
//GlobalGetAtomNameA	3.51 and higher	documented
//GlobalGetAtomNameW	3.51 and higher	documented
//GlobalHandle	3.51 and higher	documented
//GlobalLock16 (25)	4.0 to 4.90 (Windows only)	 
//GlobalMemoryStatus	3.51 and higher	documented
//GlobalMemoryStatusEx	5.0 and higher	documented
//GlobalSize	3.51 and higher	documented
//GlobalSize16 (32)	4.0 to 4.90 (Windows only)	 
//GlobalUnWire	3.51 and higher	documented
//GlobalUnWire16 (30)	4.0 to 4.90 (Windows only)	 
//GlobalUnfix	3.51 and higher	documented
//GlobalUnfix16 (28)	4.0 to 4.90 (Windows only)	 
GlobalAlloc :: (uFlags : UINT, dwBytes : SIZE_T) -> HGLOBAL #foreign kernel32;
GlobalReAlloc :: (hMem : HGLOBAL, dwBytes : SIZE_T, uFlags : UINT) -> HGLOBAL #foreign kernel32;
GlobalFree :: (hMem : HGLOBAL) -> HGLOBAL #foreign kernel32;

GMEM_FIXED    : UINT : 0x0000;
GMEM_MOVEABLE : UINT : 0x0002;
GMEM_ZEROINIT : UINT : 0x0040;
GPTR          : UINT : 0x0040;
GHND          : UINT : 0x0042;

GlobalLock :: (hMem : HGLOBAL) -> *VOID #foreign kernel32;
GlobalUnlock :: (hMem : HGLOBAL) -> BOOL #foreign kernel32;
//GlobalUnlock16 (26)	4.0 to 4.90 (Windows only)	 
//GlobalWire	3.51 and higher	documented
//GlobalWire16 (29)	4.0 to 4.90 (Windows only)	 
//Heap32First	4.0 and higher	documented
//Heap32ListFirst	4.0 and higher	documented
//Heap32ListNext	4.0 and higher	documented
//Heap32Next	4.0 and higher	documented
//HeapAlloc	3.51 and higher	documented
//HeapCompact	3.51 and higher	documented
//HeapCreate	3.51 and higher	documented
//HeapCreateTagsW	3.51 to 5.2 (NT only)	 
//HeapDestroy	3.51 and higher	documented
//HeapExtend	3.51 to 5.2 (NT only)	 
//HeapFree	3.51 and higher	documented
//HeapLock	3.51 and higher	documented
//HeapQueryInformation	5.1 and higher	documented
//HeapQueryTagW	3.51 to 5.2 (NT only)	 
//HeapReAlloc	3.51 and higher	documented
//HeapSetFlags	4.0 to 4.90 (Windows only)	 
//HeapSetInformation	5.1 and higher	documented
//HeapSize	3.51 and higher	documented
//HeapSummary	3.51 and higher (NT only)	 
//HeapUnlock	3.51 and higher	documented
//HeapUsage	3.51 to 5.2 (NT only)	 
//HeapValidate	3.51 and higher	documented
//HeapWalk	3.51 and higher	documented
//HouseCleanLogicallyDeadHandles (33)	4.0 to 4.90 (Windows only)	 
//IdnToAscii	6.0 and higher	documented
//IdnToNameprepUnicode	6.0 and higher	documented
//IdnToUnicode	6.0 and higher	documented
//InitAtomTable	3.51 and higher	documented
//InitOnceBeginInitialize	6.0 and higher	documented
//InitOnceComplete	6.0 and higher	documented
//InitOnceExecuteOnce	6.0 and higher	documented
//InitOnceInitialize	6.0 and higher	documented
//InitializeConditionVariable	6.0 and higher	documented
//InitializeContext	6.1 from Windows 7 SP1, and higher	documented
//InitializeCriticalSection	3.51 and higher	documented
//InitializeCriticalSectionAndSpinCount	4.0 from Windows NT 4.0 SP3, and higher	documented
//InitializeCriticalSectionEx	6.0 and higher	documented
//InitializeExtendedContext	6.1 before Windows 7 SP1	documented
//InitializeProcThreadAttributeList	6.0 and higher	documented
//InitializeSListHead	5.1 and higher	documented
//InitializeSRWLock	6.0 and higher	documented
//InitializeSynchronizationBarrier	6.3 and higher	documented
//InstallELAMCertificateInfo	6.3 and higher	documented
//InterlockedCompareExchange	4.0 from Windows NT 4.0, and higher (x86 only)	documented
//InterlockedCompareExchange64	5.2 and higher (x86 only)	documented
//InterlockedDecrement	3.51 and higher (x86 only)	documented
//InterlockedExchange	3.51 and higher (x86 only)	documented
//InterlockedExchangeAdd	4.0 from Windows NT 4.0, and higher (x86 only)	documented
//InterlockedFlushSList	5.1 and higher	documented
//InterlockedIncrement	3.51 and higher (x86 only)	documented
//InterlockedPopEntrySList	5.1 and higher	documented
//InterlockedPushEntrySList	5.1 and higher	documented
//InterlockedPushListSList	6.0 and higher	 
//InterlockedPushListSListEx	6.2 and higher	documented
//InvalidateConsoleDIBits	3.51 and higher (NT only)	 
//InvalidateNLSCache	4.0 to 4.90 (Windows only)	 
//IsBadCodePtr	3.51 and higher	documented
//IsBadHugeReadPtr	3.51 and higher	documented
//IsBadHugeWritePtr	3.51 and higher	documented
//IsBadReadPtr	3.51 and higher	documented
//IsBadStringPtrA	3.51 and higher	documented
//IsBadStringPtrW	3.51 and higher	documented
//IsBadWritePtr	3.51 and higher	documented
//IsCalendarLeapDay	6.0 and higher	 
//IsCalendarLeapMonth	6.0 and higher	 
//IsCalendarLeapYear	6.0 and higher	documented
//IsDBCSLeadByte	3.51 and higher	documented
//IsDBCSLeadByteEx	3.51 and higher	documented
//IsDebuggerPresent	3.51 and higher (NT);
//4.10 to 4.90 (Windows)	documented
//IsLSCallback	4.0 to 4.90 (Windows only)	 
//IsNLSDefinedString	5.2 and higher	documented
//IsNativeVhdBoot	6.2 and higher	documented
//IsNormalizedString	6.0 and higher	documented
//IsProcessCritical	6.3 and higher	documented
//IsProcessInJob	5.1 and higher	documented
//IsProcessorFeaturePresent	4.0 from Windows NT 4.0, and higher	documented
//IsSLCallback	4.0 to 4.90 (Windows only)	 
//IsSystemResumeAutomatic	4.10 and higher	documented
//IsThreadAFiber	6.0 and higher	documented
//IsThreadId (71)	4.0 to 4.90 (Windows only)	 
//IsThreadpoolTimerSet	6.0 and higher	documented
//IsTimeZoneRedirectionEnabled	5.2 to 6.1	 
//IsValidCalDateTime	6.0 and higher	 
//IsValidCodePage	3.51 and higher	documented
//IsValidLanguageGroup	4.90 and higher	documented
//IsValidLocale	3.51 and higher	documented
//IsValidLocaleName	6.0 and higher	documented
//IsValidNLSVersion	6.2 and higher	documented
//IsValidUILanguage	5.1 and 5.2	 
//IsWow64Process	5.1 and higher	documented
//K32EmptyWorkingSet	6.1 and higher	documented (PSAPI)
//K32EnumDeviceDrivers	6.1 and higher	documented (PSAPI)
//K32EnumPageFilesA	6.1 and higher	documented (PSAPI)
//K32EnumPageFilesW	6.1 and higher	documented (PSAPI)
//K32EnumProcessModules	6.1 and higher	documented (PSAPI)
//K32EnumProcessModulesEx	6.1 and higher	documented (PSAPI)
//K32EnumProcesses	6.1 and higher	documented (PSAPI)
//K32GetDeviceDriverBaseNameA	6.1 and higher	documented (PSAPI)
//K32GetDeviceDriverBaseNameW	6.1 and higher	documented (PSAPI)
//K32GetDeviceDriverFileNameA	6.1 and higher	documented (PSAPI)
//K32GetDeviceDriverFileNameW	6.1 and higher	documented (PSAPI)
//K32GetMappedFileNameA	6.1 and higher	documented (PSAPI)
//K32GetMappedFileNameW	6.1 and higher	documented (PSAPI)
//K32GetModuleBaseNameA	6.1 and higher	documented (PSAPI)
//K32GetModuleBaseNameW	6.1 and higher	documented (PSAPI)
//K32GetModuleFileNameExA	6.1 and higher	documented (PSAPI)
//K32GetModuleFileNameExW	6.1 and higher	documented (PSAPI)
//K32GetModuleInformation	6.1 and higher	documented (PSAPI)
//K32GetPerformanceInfo	6.1 and higher	documented (PSAPI)
//K32GetProcessImageFileNameA	6.1 and higher	documented (PSAPI)
//K32GetProcessImageFileNameW	6.1 and higher	documented (PSAPI)
//K32GetProcessMemoryInfo	6.1 and higher	documented (PSAPI)
//K32GetWsChanges	6.1 and higher	documented (PSAPI)
//K32GetWsChangesEx	6.1 and higher	documented (PSAPI)
//K32InitializeProcessForWsWatch	6.1 and higher	documented (PSAPI)
//K32QueryWorkingSet	6.1 and higher	documented (PSAPI)
//K32QueryWorkingSetEx	6.1 and higher	documented (PSAPI)
//K32Thk1632Epilog	4.0 to 4.90 (Windows only)	 
//K32Thk1632Prolog	4.0 to 4.90 (Windows only)	 
//K32_NtCreateFile	4.10 and 4.90	 
//K32_RtlNtStatusToDosError	4.10 and 4.90	 
//LCIDToLocaleName	6.0 and higher	documented
//LCMapStringA	3.51 and higher	documented
//LCMapStringEx	6.0 and higher	documented
//LCMapStringW	3.51 and higher	documented
//LZClose	5.1 and higher	documented
//LZCloseFile	5.1 and higher	 
//LZCopy	5.1 and higher	documented
//LZCreateFileW	5.1 and higher	 
//LZDone	5.1 and higher	documented
//LZInit	5.1 and higher	documented
//LZOpenFileA	5.1 and higher	documented
//LZOpenFileW	5.1 and higher	documented
//LZRead	5.1 and higher	documented
//LZSeek	5.1 and higher	documented
//LZStart	5.1 and higher	documented
//LeaveCriticalSection	3.51 and higher	documented
//LeaveCriticalSectionWhenCallbackReturns	6.0 and higher	documented
//LoadAppInitDlls	6.1 and higher	 
//LoadLibrary16 (35)	4.0 to 4.90 (Windows only)	 
//LoadLibraryA	3.51 and higher	documented
//LoadLibraryExA	3.51 and higher	documented
//LoadLibraryExW	3.51 and higher	documented
//LoadLibraryW	3.51 and higher	documented
//LoadModule	3.51 and higher	documented
//LoadPackagedLibrary	6.2 and higher	documented
//LoadResource	3.51 and higher	documented
//LoadStringBaseExW	6.0 and higher	 
//LoadStringBaseW	6.0 and higher	 
//LocalAlloc	3.51 and higher	documented
//LocalCompact	3.51 and higher	documented
//LocalFileTimeToFileTime	3.51 and higher	documented
//LocalFlags	3.51 and higher	documented
//LocalFree	3.51 and higher	documented
//LocalHandle	3.51 and higher	documented
//LocalLock	3.51 and higher	documented
//LocalReAlloc	3.51 and higher	documented
//LocalShrink	3.51 and higher	documented
//LocalSize	3.51 and higher	documented
//LocalUnlock	3.51 and higher	documented
//LocaleNameToLCID	6.0 and higher	documented
//LocateExtendedFeature	6.1 before Windows 7 SP1	documented
//LocateLegacyContext	6.1 before Windows 7 SP1	documented
//LocateXStateFeature	6.1 from Windows 7 SP1, and higher	documented
//LockFile	3.51 and higher	documented
//LockFileEx	3.51 and higher	documented
//LockResource	3.51 and higher	documented
//LogApiThkLSF (42)	4.0 to 4.90 (Windows only)	 
//LogApiThkSL (44)	4.0 to 4.90 (Windows only)	 
//LogCBThkSL (47)	4.0 to 4.90 (Windows only)	 
//MakeCriticalSectionGlobal	4.0 to 4.90 (Windows only)	 
//MapHInstLS	4.0 to 4.90 (Windows only)	 
//MapHInstLS_PN	4.0 to 4.90 (Windows only)	 
//MapHInstSL	4.0 to 4.90 (Windows only)	 
//MapHInstSL_PN	4.0 to 4.90 (Windows only)	 
//MapHModuleLS	4.0 to 4.90 (Windows only)	 
//MapHModuleSL	4.0 to 4.90 (Windows only)	 
//MapSL	4.0 to 4.90 (Windows only)	 
//MapSLFix	4.0 to 4.90 (Windows only)	 
//MapUserPhysicalPages	5.0 and higher	documented
//MapUserPhysicalPagesScatter	5.0 and higher	documented
//MapViewOfFile	3.51 and higher	documented
//MapViewOfFileEx	3.51 and higher	documented
//MapViewOfFileExNuma	6.0 and higher	documented
//MapViewOfFileFromApp	6.2 and higher	documented
//Module32First	4.0 and higher	documented
//Module32FirstW	5.0 and higher	documented
//Module32Next	4.0 and higher	documented
//Module32NextW	5.0 and higher	documented
//MoveFileA	3.51 and higher	documented
//MoveFileExA	3.51 and higher	documented
//MoveFileExW	3.51 and higher	documented
//MoveFileTransactedA	6.0 and higher	documented
//MoveFileTransactedW	6.0 and higher	documented
//MoveFileW	3.51 and higher	documented
//MoveFileWithProgressA	5.0 and higher	documented
//MoveFileWithProgressW	5.0 and higher	documented
//MulDiv	3.51 and higher	documented
//NeedCurrentDirectoryForExePathA	5.2 and higher	documented
//NeedCurrentDirectoryForExePathW	5.2 and higher	documented
//NlsCheckPolicy	6.0 and higher	 
//NlsConvertIntegerToString	5.0 to 6.0	 
//NlsEventDataDescCreate	6.0 and higher	 
//NlsGetCacheUpdateCount	5.0 and higher	 
//NlsResetProcessLocale	5.0 to 5.2	 
//NlsUpdateLocale	6.0 and higher	 
//NlsUpdateSystemLocale	6.0 and higher	 
//NlsWriteEtwEvent	6.0 and higher	 
//NormalizeString	6.0 and higher	documented
//NotifyMountMgr	6.1 and higher	 
//NotifyNLSUserCache	4.0 to 4.90 (Windows only)	 
//NotifyUILanguageChange	6.0 and higher	 
//NtVdm64CreateProcessInternalW	6.2 and higher	 
//NumaVirtualQueryNode	5.1 only	 
//OOBEComplete	6.3 and higher	documented
//OT_32ThkLSF (40)	4.0 to 4.90 (Windows only)	 
//OfferVirtualMemory	10.0 and higher	documented
//OpenConsoleW	3.51 and higher (NT only)	 
//OpenConsoleWStub	6.2 and higher	 
//OpenDataFile	5.0 to 5.2	 
//OpenEventA	3.51 and higher	documented
//OpenEventW	3.51 and higher	documented
//OpenFile	3.51 and higher	documented
//OpenFileById	6.0 and higher	documented
//OpenFileMappingA	3.51 and higher	documented
//OpenFileMappingW	3.51 and higher	documented
//OpenJobObjectA	5.0 and higher	documented
//OpenJobObjectW	5.0 and higher	documented
//OpenMutexA	3.51 and higher	documented
//OpenMutexW	3.51 and higher	documented
//OpenPackageInfoByFullName	6.2 and higher	documented
//OpenPrivateNamespaceA	6.0 and higher	documented
//OpenPrivateNamespaceW	6.0 and higher	documented
//OpenProcess	3.51 and higher	documented
//OpenProcessToken	6.1 and higher;
//earlier in ADVAPI32	documented (ADVAPI32)
//OpenProfileUserMapping	3.51 and higher	 
//OpenSemaphoreA	3.51 and higher	documented
//OpenSemaphoreW	3.51 and higher	documented
//OpenState	6.2 and higher	 
//OpenStateAtom	6.2 only	 
//OpenStateExplicit	6.2 and higher	 
//OpenThread	4.90 and higher	documented
//OpenThreadToken	6.1 and higher;
//earlier in ADVAPI32	documented (ADVAPI32)
//OpenVxDHandle	4.0 to 4.90 (Windows only)	 
//OpenWaitableTimerA	4.0 from Windows NT 4.0, and higher	documented
//OpenWaitableTimerW	4.0 from Windows NT 4.0, and higher	documented
//OutputDebugStringA	3.51 and higher	documented
//OutputDebugStringW	3.51 and higher	documented
//OverrideRoamingDataModificationTimesInRange	6.2 only	 
//PK16FNF (91)	4.0 to 4.90 (Windows only)	 
//PackageFamilyNameFromFullName	6.2 and higher	documented
//PackageFamilyNameFromId	6.2 and higher	documented
//PackageFullNameFromId	6.2 and higher	documented
//PackageIdFromFullName	6.2 and higher	documented
//PackageNameAndPublisherIdFromFamilyName	6.2 and higher	documented
//ParseApplicationUserModelId	6.3 and higher	documented
//PeekConsoleInputA	3.51 and higher	documented
//PeekConsoleInputW	3.51 and higher	documented
//PeekNamedPipe	3.51 and higher	documented
//PostQueuedCompletionStatus	3.51 and higher	documented
//PowerClearRequest	6.1 and higher	documented
//PowerCreateRequest	6.1 and higher	documented
//PowerSetRequest	6.1 and higher	documented
//PrefetchVirtualMemory	6.2 and higher	documented
//PrepareTape	3.51 and higher	documented
//PrivCopyFileExW	5.0 and higher	 
//PrivMoveFileIdentityW	5.0 and higher	 
//Process32First	4.0 and higher	documented
//Process32FirstW	5.0 and higher	documented
//Process32Next	4.0 and higher	documented
//Process32NextW	5.0 and higher	documented
//ProcessIdToSessionId	5.0 and higher	documented
//PssCaptureSnapshot	6.3 and higher	documented
//PssDuplicateSnapshot	6.3 and higher	documented
//PssFreeSnapshot	6.3 and higher	documented
//PssQuerySnapshot	6.3 and higher	documented
//PssWalkMarkerCreate	6.3 and higher	documented
//PssWalkMarkerFree	6.3 and higher	documented
//PssWalkMarkerGetPosition	6.3 and higher	documented
//PssWalkMarkerRewind	6.3 and higher	 
//PssWalkMarkerSeek	6.3 and higher	 
//PssWalkMarkerSeekToBeginning	6.3 and higher	documented
//PssWalkMarkerSetPosition	6.3 and higher	documented
//PssWalkMarkerTell	6.3 and higher	 
//PssWalkSnapshot	6.3 and higher	documented
//PublishStateChangeNotification	6.2 only	 
//PulseEvent	3.51 and higher	documented
//PurgeComm	3.51 and higher	documented
//QT_Thunk	4.0 to 4.90 (Windows only)	 
//QT_ThunkPrime (90)	4.0 to 4.90 (Windows only)	 
//QueryActCtxSettingsW	6.0 and higher	documented
//QueryActCtxSettingsWWorker	6.2 and higher	 
//QueryActCtxW	5.1 and higher	documented
//QueryActCtxWWorker	6.2 and higher	 
//QueryDepthSList	5.1 and higher	documented
//QueryDosDeviceA	3.51 and higher	documented
//QueryDosDeviceW	3.51 and higher	documented
//QueryFullProcessImageNameA	6.0 and higher	documented
//QueryFullProcessImageNameW	6.0 and higher	documented
//QueryIdleProcessorCycleTime	6.0 and higher	documented
//QueryIdleProcessorCycleTimeEx	6.1 and higher	documented
//QueryInformationJobObject	5.0 and higher	documented
//QueryIoRateControlInformationJobObject	10.0 and higher	documented
//QueryMemoryResourceNotification	5.1 and higher	documented
//QueryNumberOfEventLogRecords	4.0 to 4.90 (Windows only)	 
//QueryOldestEventLogRecord	4.0 to 4.90 (Windows only)	 
QueryPerformanceCounter   :: (lpPerformanceCount : *s64) -> BOOL #foreign kernel32;
QueryPerformanceFrequency :: (lpFrequency : *s64) -> BOOL #foreign kernel32;
//QueryProcessAffinityUpdateMode	6.0 from Windows Vista SP1, and higher	documented
//QueryProcessCycleTime	6.0 and higher	documented
//QueryProtectedPolicy	10.0 and higher	documented
//QueryStateAtomValueInfo	6.2 only	 
//QueryStateContainerItemInfo	6.2 only	 
//QueryThreadCycleTime	6.0 and higher	documented
//QueryThreadProfiling	6.1 and higher	documented
//QueryThreadpoolStackInformation	6.1 and higher	documented
//QueryUmsThreadInformation	6.1 and higher (x64 only)	documented
//QueryUnbiasedInterruptTime	6.1 and higher	documented
//QueueUserAPC	4.0 and higher	documented
//QueueUserWorkItem	5.0 and higher	documented
//QueryWin31IniFilesMappedToRegistry	3.51 to 5.1 (NT only)	 
//QuirkGetData2Worker	6.3 and higher	 
//QuirkGetDataWorker	6.3 and higher	 
//QuirkIsEnabled2Worker	6.3 and higher	 
//QuirkIsEnabled3Worker	6.3 and higher	 
//QuirkIsEnabledForPackage2Worker	6.3 and higher	 
//QuirkIsEnabledForPackage3Worker	10.0 and higher	 
//QuirkIsEnabledForPackage4Worker	10.0 and higher	 
//QuirkIsEnabledForPackageWorker	6.3 and higher	 
//QuirkIsEnabledForProcessWorker	6.3 and higher	 
//QuirkIsEnabledWorker	6.3 and higher	 
//RPCHACKORAMA (104)	4.10 and 4.90	 
//RaiseException	3.51 and higher	documented
//RaiseFailFastException	6.1 and higher	documented
//RaiseInvalid16BitExeError	6.2 and higher	 
//ReOpenFile	5.2 and higher	documented
//ReadConsoleA	3.51 and higher	documented
//ReadConsoleInputA	3.51 and higher	documented
//ReadConsoleInputExA	4.0 and higher (NT only)	 
//ReadConsoleInputExW	4.0 and higher (NT only)	 
//ReadConsoleInputW	3.51 and higher	documented
//ReadConsoleOutputA	3.51 and higher	documented
//ReadConsoleOutputAttribute	3.51 and higher	documented
//ReadConsoleOutputCharacterA	3.51 and higher	documented
//ReadConsoleOutputCharacterW	3.51 and higher	documented
//ReadConsoleOutputW	3.51 and higher	documented
//ReadConsoleW	3.51 and higher	documented
//ReadDirectoryChangesW	3.51 from Windows NT 3.51 SP5, and higher (NT);
//4.10 to 4.90 (Windows)	documented
//ReadFile	3.51 and higher	documented
//ReadFileEx	3.51 and higher	documented
//ReadFileScatter	4.0 from Windows NT 4.0 SP3, and higher	documented
//ReadProcessMemory	3.51 and higher	documented
//ReadStateAtomValue	6.2 only	 
//ReadStateContainerValue	6.2 only	 
//ReadThreadProfilingData	6.1 and higher	documented
//ReclaimVirtualMemory	10.0 and higher	documented
//RefreshDaylightInformation (99)	4.0 to 4.90 (Windows only)	 
//RegCloseKey	6.1 and higher;
//earlier in ADVAPI32	documented (ADVAPI32)
//RegCopyTreeW	6.2 and higher;
//earlier in ADVAPI32	documented (ADVAPI32)
//RegCreateKeyExA	6.1 and higher;
//earlier in ADVAPI32	documented (ADVAPI32)
//RegCreateKeyExW	6.1 and higher;
//earlier in ADVAPI32	documented (ADVAPI32)
//RegDeleteKeyExA	6.1 and higher;
//earlier in ADVAPI32	documented (ADVAPI32)
//RegDeleteKeyExW	6.1 and higher;
//earlier in ADVAPI32	documented (ADVAPI32)
//RegDeleteTreeA	6.1 and higher;
//earlier in ADVAPI32	documented (ADVAPI32)
//RegDeleteTreeW	6.1 and higher;
//earlier in ADVAPI32	documented (ADVAPI32)
//RegDeleteValueA	6.1 and higher;
//earlier in ADVAPI32	documented (ADVAPI32)
//RegDeleteValueW	6.1 and higher;
//earlier in ADVAPI32	documented (ADVAPI32)
//RegDisablePredefinedCacheEx	6.1 and higher;
//earlier in ADVAPI32	documented (ADVAPI32)
//RegEnumKeyExA	6.1 and higher;
//earlier in ADVAPI32	documented (ADVAPI32)
//RegEnumKeyExW	6.1 and higher;
//earlier in ADVAPI32	documented (ADVAPI32)
//RegEnumValueA	6.1 and higher;
//earlier in ADVAPI32	documented (ADVAPI32)
//RegEnumValueW	6.1 and higher;
//earlier in ADVAPI32	documented (ADVAPI32)
//RegFlushKey	6.1 and higher;
//earlier in ADVAPI32	documented (ADVAPI32)
//RegGetKeySecurity	6.1 and higher;
//earlier in ADVAPI32	documented (ADVAPI32)
//RegGetValueA	6.1 and higher;
//earlier in ADVAPI32	documented (ADVAPI32)
//RegGetValueW	6.1 and higher;
//earlier in ADVAPI32	documented (ADVAPI32)
//RegKrnGetGlobalState	6.1 only	 
//RegKrnInitialize	6.1 only	 
//RegLoadKeyA	6.1 and higher;
//earlier in ADVAPI32	documented (ADVAPI32)
//RegLoadKeyW	6.1 and higher;
//earlier in ADVAPI32	documented (ADVAPI32)
//RegLoadMUIStringA	6.1 and higher;
//earlier in ADVAPI32	documented (ADVAPI32)
//RegLoadMUIStringW	6.1 and higher;
//earlier in ADVAPI32	documented (ADVAPI32)
//RegNotifyChangeKeyValue	6.1 and higher;
//earlier in ADVAPI32	documented (ADVAPI32)
//RegOpenCurrentUser	6.1 and higher;
//earlier in ADVAPI32	documented (ADVAPI32)
//RegOpenKeyExA	6.1 and higher;
//earlier in ADVAPI32	documented (ADVAPI32)
//RegOpenKeyExW	6.1 and higher;
//earlier in ADVAPI32	documented (ADVAPI32)
//RegOpenUserClassesRoot	6.1 and higher;
//earlier in ADVAPI32	documented (ADVAPI32)
//RegQueryInfoKeyA	6.1 and higher;
//earlier in ADVAPI32	documented (ADVAPI32)
//RegQueryInfoKeyW	6.1 and higher;
//earlier in ADVAPI32	documented (ADVAPI32)
//RegQueryValueExA	6.1 and higher;
//earlier in ADVAPI32	documented (ADVAPI32)
//RegQueryValueExW	6.1 and higher;
//earlier in ADVAPI32	documented (ADVAPI32)
//RegRestoreKeyA	6.1 and higher;
//earlier in ADVAPI32	documented (ADVAPI32)
//RegRestoreKeyW	6.1 and higher;
//earlier in ADVAPI32	documented (ADVAPI32)
//RegSaveKeyExA	6.1 and higher;
//earlier in ADVAPI32	documented (ADVAPI32)
//RegSaveKeyExW	6.1 and higher;
//earlier in ADVAPI32	documented (ADVAPI32)
//RegSetKeySecurity	6.1 and higher;
//earlier in ADVAPI32	documented (ADVAPI32)
//RegSetValueExA	6.1 and higher;
//earlier in ADVAPI32	documented (ADVAPI32)
//RegSetValueExW	6.1 and higher;
//earlier in ADVAPI32	documented (ADVAPI32)
//RegUnLoadKeyA	6.1 and higher;
//earlier in ADVAPI32	documented (ADVAPI32)
//RegUnLoadKeyW	6.1 and higher;
//earlier in ADVAPI32	documented (ADVAPI32)
//RegisterApplicationRecoveryCallback	6.0 and higher	documented
//RegisterApplicationRestart	6.0 and higher	documented
//RegisterBadMemoryNotification	6.2 and higher	documented
//RegisterConsoleIME	5.0 and higher	 
//RegisterConsoleOS2	5.0 and higher	 
//RegisterConsoleVDM	3.51 and higher;
//NT only	 
//RegisterServiceProcess	4.0 to 4.90 (Windows only)	 
//RegisterStateChangeNotification	6.2 only	 
//RegisterStateLock	6.2 only	 
//RegisterSysMsgHandler	4.10 and 4.90	 
//RegisterWaitForInputIdle	3.51 and higher (NT only)	 
//RegisterWaitForSingleObject	5.0 and higher	documented
//RegisterWaitForSingleObjectEx	5.0 and higher	 
//RegisterWaitUntilOOBECompleted	6.3 and higher	documented
//RegisterWowBaseHandlers	3.51 and higher (NT only)	 
//RegisterWowExec	3.51 and higher (NT only)	 
//ReinitializeCriticalSection	4.0 to 4.90 (Windows only)	 
//ReleaseActCtx	5.1 and higher	documented
//ReleaseActCtxWorker	6.2 and higher	 
//ReleaseMutex	3.51 and higher	documented
//ReleaseMutexWhenCallbackReturns	6.0 and higher	documented
//ReleaseSRWLockExclusive	6.0 and higher	documented
//ReleaseSRWLockShared	6.0 and higher	documented
//ReleaseSemaphore	3.51 and higher	documented
//ReleaseSemaphoreWhenCallbackReturns	6.0 and higher	documented
//ReleaseStateLock	6.2 only	 
//ReleaseThunkLock (48)	4.0 to 4.90 (Windows only)	 
//RemoveDirectoryA	3.51 and higher	documented
//RemoveDirectoryTransactedA	6.0 and higher	documented
//RemoveDirectoryTransactedW	6.0 and higher	documented
//RemoveDirectoryW	3.51 and higher	documented
//RemoveDllDirectory	6.2 and higher	documented
//RemoveLocalAlternateComputerNameA	5.1 and higher	 
//RemoveLocalAlternateComputerNameW	5.1 and higher	 
//RemoveSecureMemoryCacheCallback	6.0 from Windows Vista SP1, and higher	documented
//RemoveVectoredContinueHandler	5.2 from Windows Server 2003 SP1, and higher	documented
//RemoveVectoredExceptionHandler	5.1 and higher	documented
//ReplaceFile	5.0 and higher	documented
//ReplaceFileA	5.0 and higher	documented
//ReplaceFileW	5.0 and higher	documented
//ReplacePartitionUnit	6.0 from Windows Vista SP1, and higher (x86 only)	 
//RequestDeviceWakeup	4.10 and higher	 
//RequestWakeupLatency	4.10 and higher	documented
//ResetEvent	3.51 and higher	documented
//ResetNLSUserInfoCache	4.10 and 4.90	 
//ResetState	6.2 only	 
//ResetWriteWatch	4.10 and higher	documented
//ResolveDelayLoadedAPI	6.2 and higher	documented
//ResolveDelayLoadsFromDll	6.2 and higher	documented
//ResolveLocaleName	6.1 and higher	documented
//RestoreLastError	5.1 and higher	 
//RestoreThunkLock (49)	4.0 to 4.90 (Windows only)	 
//ResumeThread	3.51 and higher	documented
//RtlAddFunctionTable	5.2 from Windows Server 2003 SP1, and higher (x64 only)	documented
//RtlCaptureContext	5.1 and higher	documented
//RtlCaptureStackBackTrace	5.1 and higher	documented
//RtlCompareMemory	5.2 from Windows Server 2003 SP1, and higher (x64 only)	documented (WDK)
//RtlCopyMemory	5.2 from Windows Server 2003 SP1, and higher (x64 only)	documented (WDK)
//RtlConvertLongToLargeInteger (84)	4.0 to 4.90 (Windows only)	documented (WDK)
//RtlConvertUlongToLargeInteger (85)	4.0 to 4.90 (Windows only)	documented (WDK)
//RtlDeleteFunctionTable	5.2 from Windows Server 2003 SP1, and higher (x64 only)	documented
//RtlEnlargedIntegerDivide (76)	4.0 to 4.90 (Windows only)	 
//RtlEnlargedIntegerMultiply (73)	4.0 to 4.90 (Windows only)	documented (WDK)
//RtlEnlargedUnsignedDivide (75)	4.0 to 4.90 (Windows only)	documented (WDK)
//RtlEnlargedUnsignedMultiply (74)	4.0 to 4.90 (Windows only)	documented (WDK)
//RtlExtendedIntegerMultiply (78)	4.0 to 4.90 (Windows only)	documented (WDK)
//RtlExtendedMagicDivide (77)	4.0 to 4.90 (Windows only)	documented (WDK)
//RtlFillMemory	3.51 and higher	documented (WDK)
//RtlInstallFunctionTableCallback	5.2 from Windows Server 2003 SP1, and higher (x64 only)	documented
//RtlLargeIntegerAdd (72)	4.0 to 4.90 (Windows only)	documented (WDK)
//RtlLargeIntegerArithmeticShift (81)	4.0 to 4.90 (Windows only)	documented (WDK)
//RtlLargeIntegerNegate (82)	4.0 to 4.90 (Windows only)	documented (WDK)
//RtlLargeIntegerShiftLeft (79)	4.0 to 4.90 (Windows only)	documented (WDK)
//RtlLargeIntegerShiftRight (80)	4.0 to 4.90 (Windows only)	documented (WDK)
//RtlLargeIntegerSubtract (83)	4.0 to 4.90 (Windows only)	documented (WDK)
//RtlLookupFunctionEntry	5.2 from Windows Server 2003 SP1, and higher (x64 only)	documented
//RtlMoveMemory	3.51 and higher	documented (WDK)
//RtlPcToFileHeader	5.2 from Windows Server 2003 SP1, and higher (x64);
//10.0 and higher (x86)	documented
//RtlRaiseException	5.2 from Windows Server 2003 SP1, and higher (x64 only)	 
//RtlRestoreContext	5.2 from Windows Server 2003 SP1, and higher (x64 only)	documented
//RtlUnwind	3.51 and higher	documented for settlement
//RtlUnwindEx	5.2 from Windows Server 2003 SP1, and higher (x64 only)	documented
//RtlVirtualUnwind	5.2 from Windows Server 2003 SP1, and higher (x64 only)	documented
//RtlZeroMemory	3.51 and higher	documented (WDK)
//SMapLS	4.0 to 4.90 (Windows only)	 
//SMapLS_IP_EBP_12	4.0 to 4.90 (Windows only)	 
//SMapLS_IP_EBP_16	4.0 to 4.90 (Windows only)	 
//SMapLS_IP_EBP_20	4.0 to 4.90 (Windows only)	 
//SMapLS_IP_EBP_24	4.0 to 4.90 (Windows only)	 
//SMapLS_IP_EBP_28	4.0 to 4.90 (Windows only)	 
//SMapLS_IP_EBP_32	4.0 to 4.90 (Windows only)	 
//SMapLS_IP_EBP_36	4.0 to 4.90 (Windows only)	 
//SMapLS_IP_EBP_40	4.0 to 4.90 (Windows only)	 
//SMapLS_IP_EBP_8	4.0 to 4.90 (Windows only)	 
//SSCall (88)	4.0 to 4.90 (Windows only)	 
//SSOnBigStack (87)	4.0 to 4.90 (Windows only)	 
//SUnMapLS	4.0 to 4.90 (Windows only)	 
//SUnMapLS_IP_EBP_12	4.0 to 4.90 (Windows only)	 
//SUnMapLS_IP_EBP_16	4.0 to 4.90 (Windows only)	 
//SUnMapLS_IP_EBP_20	4.0 to 4.90 (Windows only)	 
//SUnMapLS_IP_EBP_24	4.0 to 4.90 (Windows only)	 
//SUnMapLS_IP_EBP_28	4.0 to 4.90 (Windows only)	 
//SUnMapLS_IP_EBP_32	4.0 to 4.90 (Windows only)	 
//SUnMapLS_IP_EBP_36	4.0 to 4.90 (Windows only)	 
//SUnMapLS_IP_EBP_40	4.0 to 4.90 (Windows only)	 
//SUnMapLS_IP_EBP_8	4.0 to 4.90 (Windows only)	 
//ScrollConsoleScreenBufferA	3.51 and higher	documented
//ScrollConsoleScreenBufferW	3.51 and higher	documented
//SearchPathA	3.51 and higher	documented
//SearchPathW	3.51 and higher	documented
//SetCPGlobal	5.0 to 5.2	 
//SetCachedSigningLevel	6.2 and higher	 
//SetCalendarInfoA	4.10 and higher	documented
//SetCalendarInfoW	4.10 and higher	documented
//SetClientTimeZoneInformation	5.1 to 6.1	 
//SetComPlusPackageInstallStatus	5.1 and higher	 
//SetCommBreak	3.51 and higher	documented
//SetCommConfig	3.51 and higher	documented
//SetCommMask	3.51 and higher	documented
//SetCommState	3.51 and higher	documented
//SetCommTimeouts	3.51 and higher	documented
//SetComputerNameA	3.51 and higher	documented
//SetComputerNameEx2W	6.3 and higher	 
//SetComputerNameExA	5.0 and higher	documented
//SetComputerNameExW	5.0 and higher	documented
//SetComputerNameW	3.51 and higher	documented
//SetConsoleActiveScreenBuffer	3.51 and higher	documented
//SetConsoleCP	3.51 and higher	documented
//SetConsoleCommandHistoryMode	3.51 to 5.2 (NT only)	 
//SetConsoleCtrlHandler	3.51 and higher	documented
//SetConsoleCursor	3.51 and higher (NT only)	 
//SetConsoleCursorInfo	3.51 and higher	documented
//SetConsoleCursorMode	5.0 and higher	 
//SetConsoleCursorPosition	3.51 and higher	documented
//SetConsoleDisplayMode	3.51 and higher (NT only)	documented
//SetConsoleFont	3.51 and higher (NT only)	 
//SetConsoleHardwareState	3.51 and higher (NT only)	 
//SetConsoleHistoryInfo	6.0 and higher	documented
//SetConsoleIcon	4.0 and higher (NT only)	 
//SetConsoleInputExeNameA	4.0 and higher (NT only)	 
//SetConsoleInputExeNameW	4.0 and higher (NT only)	 
//SetConsoleKeyShortcuts	3.51 and higher (NT only)	 
//SetConsoleLocalEUDC	5.0 and higher	 
//SetConsoleMaximumWindowSize	3.51 and higher (NT only)	 
//SetConsoleMenuClose	3.51 and higher (NT only)	 
//SetConsoleMode	3.51 and higher	documented
//SetConsoleNlsMode	5.0 and higher	 
//SetConsoleNumberOfCommandsA	3.51 and higher (NT only)	 
//SetConsoleNumberOfCommandsW	3.51 and higher (NT only)	 
//SetConsoleOS2OemFormat	5.0 and higher	 
//SetConsoleOutputCP	3.51 and higher	documented
//SetConsolePalette	3.51 and higher (NT only)	 
//SetConsoleScreenBufferInfoEx	6.0 and higher	documented
//SetConsoleScreenBufferSize	3.51 and higher	documented
//SetConsoleTextAttribute	3.51 and higher	documented
//SetConsoleTitleA	3.51 and higher	documented
//SetConsoleTitleW	3.51 and higher	documented
//SetConsoleWindowInfo	3.51 and higher	documented
//SetCriticalSectionSpinCount	4.0 from Windows NT 4.0 SP3, and higher	documented
//SetCurrentConsoleFontEx	6.0 and higher	documented
//SetCurrentDirectoryA	3.51 and higher	documented
//SetCurrentDirectoryW	3.51 and higher	documented
//SetDaylightFlag	4.0 to 4.90 (Windows only)	 
//SetDefaultCommConfigA	3.51 and higher	documented
//SetDefaultCommConfigW	3.51 and higher	documented
//SetDefaultDllDirectories	6.2 and higher	documented
//SetDllDirectoryA	5.1 from Windows XP SP1, and higher	documented
//SetDllDirectoryW	5.1 from Windows XP SP1, and higher	documented
//SetDynamicTimeZoneInformation	6.0 and higher	documented
//SetEndOfFile	3.51 and higher	documented
//SetEnvironmentStringsA	5.2 and higher	 
//SetEnvironmentStringsW	5.2 and higher	 
//SetEnvironmentVariableA	3.51 and higher	documented
//SetEnvironmentVariableW	3.51 and higher	documented
//SetErrorMode	3.51 and higher	documented
//SetEvent	3.51 and higher	documented
//SetEventWhenCallbackReturns	6.0 and higher	documented
//SetExtendedFeaturesMask	6.1 before Windows 7 SP1	documented
//SetFileApisToANSI	3.51 and higher	documented
//SetFileApisToOEM	3.51 and higher	documented
//SetFileAttributesA	3.51 and higher	documented
//SetFileAttributesTransactedA	6.0 and higher	documented
//SetFileAttributesTransactedW	6.0 and higher	documented
//SetFileAttributesW	3.51 and higher	documented
//SetFileBandwidthReservation	6.0 and higher	documented
//SetFileCompletionNotificationModes	5.2 from Windows Server 2003 SP2, and higher	documented
//SetFileInformationByHandle	6.0 and higher	documented
//SetFileIoOverlappedRange	6.0 and higher	documented
//SetFilePointer	3.51 and higher	documented
//SetFilePointerEx	5.0 and higher	documented
//SetFileShortNameA	5.1 and higher	documented
//SetFileShortNameW	5.1 and higher	documented
//SetFileTime	3.51 and higher	documented
//SetFileValidData	5.1 and higher	documented
//SetFirmwareEnvironmentVariableA	5.1 and higher	documented
//SetFirmwareEnvironmentVariableExA	6.2 and higher	documented
//SetFirmwareEnvironmentVariableExW	6.2 and higher	documented
//SetFirmwareEnvironmentVariableW	5.1 and higher	documented
//SetHandleContext	4.0 to 4.90 (Windows);
//5.1 and higher (NT, x86 only)	 
//SetHandleCount	3.51 and higher	documented
//SetHandleInformation	3.51 and higher	documented
//SetInformationJobObject	5.0 and higher	documented
//SetIoRateControlInformationJobObject	10.0 and higher	documented
//SetLastConsoleEventActive	3.51 and higher (NT only)	 
//SetLastError	3.51 and higher	documented
//SetLocalPrimaryComputerNameA	5.1 and higher	 
//SetLocalPrimaryComputerNameW	5.1 and higher	 
//SetLocalTime	3.51 and higher	documented
//SetLocaleInfoA	3.51 and higher	documented
//SetLocaleInfoW	3.51 and higher	documented
//SetMailslotInfo	3.51 and higher	documented
//SetMessageWaitingIndicator	4.10 and higher	 
//SetNamedPipeAttribute	6.0 and higher	 
//SetNamedPipeHandleState	3.51 and higher	documented
//SetPriorityClass	3.51 and higher	documented
//SetProcessAffinityMask	4.0 from Windows NT 4.0, and higher	documented
//SetProcessAffinityUpdateMode	6.0 from Windows Vista SP1, and higher	documented
//SetProcessDEPPolicy	some 5.1 and 6.0, and higher;
//begins in 5.1 from Windows XP SP3;
//begins in 6.0 from Windows Vista SP1	documented
//SetProcessDefaultCpuSets	10.0 and higher	documented
//SetProcessInformation	6.2 and higher	documented
//SetProcessMitigationPolicy	6.2 and higher	documented
//SetProcessPreferredUILanguages	6.1 and higher	documented
//SetProcessPriorityBoost	4.0 from Windows NT 4.0, and higher	documented
//SetProcessShutdownParameters	3.51 and higher	documented
//SetProcessUserModeExceptionPolicy	6.1 from Windows 7 SP1 only	 
//SetProcessWorkingSetSize	3.51 and higher	documented
//SetProcessWorkingSetSizeEx	5.2 and higher	documented
//SetProtectedPolicy	10.0 and higher	documented
//SetRoamingLastObservedChangeTime	6.2 only	 
//SetSearchPathMode	6.0 from Windows Vista SP2, and higher	documented
//SetStateVersion	6.2 only	 
//SetStdHandle	3.51 and higher	documented
//SetStdHandleEx	6.0 and higher	 
//SetSystemFileCacheSize	5.2 from Windows Server 2003 SP1, and higher	documented
//SetSystemPowerState	3.51 and higher	documented
//SetSystemTime	3.51 and higher	documented
//SetSystemTimeAdjustment	3.51 and higher	documented
//SetTapeParameters	3.51 and higher	documented
//SetTapePosition	3.51 and higher	documented
//SetTaskmonControl (122)	4.10 and 4.90	 
//SetTermsrvAppInstallMode	5.0 and higher	 
//SetThreadAffinityMask	3.51 and higher	documented
//SetThreadContext	3.51 and higher	documented
//SetThreadErrorMode	6.1 and higher	documented
//SetThreadExecutionState	4.10 and higher	documented
//SetThreadGroupAffinity	6.1 and higher	documented
//SetThreadIdealProcessor	4.0 from Windows NT 4.0, and higher	documented
//SetThreadIdealProcessorEx	6.1 and higher	documented
//SetThreadInformation	6.2 and higher	documented
//SetThreadLocale	3.51 and higher	documented
//SetThreadPreferredUILanguages	6.0 and higher	documented
//SetThreadPriority	3.51 and higher	documented
//SetThreadPriorityBoost	4.0 from Windows NT 4.0, and higher	documented
//SetThreadSelectedCpuSets	10.0 and higher	documented
//SetThreadStackGuarantee	5.2 from Windows Server 2003 SP1, and higher	documented
//SetThreadToken	6.1 and higher;
//earlier in ADVAPI32	documented (ADVAPI32)
//SetThreadUILanguage	5.1 and higher	documented
//SetThreadpoolStackInformation	6.1 and higher	documented
//SetThreadpoolThreadMaximum	6.0 and higher	documented
//SetThreadpoolThreadMinimum	6.0 and higher	documented
//SetThreadpoolTimer	6.0 and higher	documented
//SetThreadpoolTimerEx	6.2 and higher	documented
//SetThreadpoolWait	6.0 and higher	documented
//SetThreadpoolWaitEx	6.2 and higher	documentation
//SetTimeZoneInformation	3.51 and higher	documented
//SetTimerQueueTimer	5.0 and higher	 
//SetUmsThreadInformation	6.1 and higher (x64 only)	documented
//SetUnhandledExceptionFilter	3.51 and higher	documented
//SetUserGeoID	4.90 only (Windows);
//5.1 and higher (NT)	documented
//SetVDMCurrentDirectories	3.51 and higher (NT only)	 
//SetVolumeLabelA	3.51 and higher	documented
//SetVolumeLabelW	3.51 and higher	documented
//SetVolumeMountPointA	5.0 and higher	documented
//SetVolumeMountPointW	5.0 and higher	documented
//SetVolumeMountPointWStub	6.2 and higher	 
//SetWaitableTimer	4.0 from Windows NT 4.0, and higher	documented
//SetWaitableTimerEx	6.1 and higher	documented
//SetXStateFeaturesMask	6.1 from Windows 7 SP1, and higher	documented
//SetupComm	3.51 and higher	documented
//ShowConsoleCursor	3.51 and higher (NT only)	 
//SignalObjectAndWait	4.0 from Windows NT 4.0, and higher	documented
//SignalSysMsgHandlers	4.10 and 4.90	 
//SizeofResource	3.51 and higher	documented
//Sleep	3.51 and higher	documented
//SleepConditionVariableCS	6.0 and higher	documented
//SleepConditionVariableSRW	6.0 and higher	documented
//SleepEx	3.51 and higher	documented
//SortCloseHandle	6.1 and higher	 
//SortGetHandle	6.1 and higher	 
//StartThreadpoolIo	6.0 and higher	documented
//SubmitThreadpoolWork	6.0 and higher	documented
//SubscribeStateChangeNotification	6.2 only	 
//SuspendThread	3.51 and higher	documented
//SwitchToFiber	3.51 from Windows NT 3.51 SP5, and higher (NT);
//4.10 to 4.90 (Windows)	documented
//SwitchToThread	4.0 from Windows NT 4.0, and higher	documented
//SystemTimeToFileTime	3.51 and higher	documented
//SystemTimeToTzSpecificLocalTime	3.51 and higher	documented
//SystemTimeToTzSpecificLocalTimeEx	6.2 and higher	documented
//TerminateJobObject	5.0 and higher	documented
//TerminateProcess	3.51 and higher	documented
//TerminateThread	3.51 and higher	documented
//TerminateThreadEx (100)	4.0 to 4.90 (Windows only)	 
//TermsrvAppInstallMode	5.0 and higher	 
//TermsrvConvertSysRootToUserDir	6.2 and higher	 
//TermsrvCreateRegEntry	6.2 and higher	 
//TermsrvDeleteKey	6.2 and higher	 
//TermsrvDeleteValue	6.2 and higher	 
//TermsrvGetPreSetValue	6.2 and higher	 
//TermsrvGetWindowsDirectoryA	6.2 and higher	 
//TermsrvGetWindowsDirectoryW	6.2 and higher	 
//TermsrvOpenRegEntry	6.2 and higher	 
//TermsrvOpenUserClasses	6.2 and higher	 
//TermsrvRestoreKey	6.2 and higher	 
//TermsrvSetKeySecurity	6.2 and higher	 
//TermsrvSetValueKey	6.2 and higher	 
//TermsrvSyncUserIniFileExt	6.2 and higher	 
//Thread32First	4.0 and higher	documented
//Thread32Next	4.0 and higher	documented
//ThunkConnect32	4.0 to 4.90 (Windows only)	 
//ThunkConnect32NonLocking (121)	4.10 and 4.90	 
//ThunkInitLS (43)	4.0 to 4.90 (Windows only)	 
//ThunkInitLSF (41)	4.0 to 4.90 (Windows only)	 
//ThunkInitSL (46)	4.0 to 4.90 (Windows only)	 
//ThunkTheTemplateHandle (19)	4.0 to 4.90 (Windows only)	 
//TlsAlloc	3.51 and higher	documented
//TlsAllocGlobal (102)	4.10 and 4.90	 
//TlsAllocInternal	4.0 to 4.90 (Windows only)	 
//TlsFree	3.51 and higher	documented
//TlsFreeGlobal (103)	4.10 and 4.90	 
//TlsFreeInternal	4.0 to 4.90 (Windows only)	 
//TlsGetValue	3.51 and higher	documented
//TlsSetValue	3.51 and higher	documented
//Toolhelp32ReadProcessMemory	4.0 and higher	documented
//TransactNamedPipe	3.51 and higher	documented
//TransmitCommChar	3.51 and higher	documented
//TrimVirtualBuffer	3.51 to 5.2 before Windows Server 2003 SP1 (NT only)	 
//TryAcquireSRWLockExclusive	6.1 and higher	documented
//TryAcquireSRWLockShared	6.1 and higher	documented
//TryEnterCriticalSection	4.0 from Windows NT 4.0, and higher	documented
//TrySubmitThreadpoolCallback	6.0 and higher	documented
//TzSpecificLocalTimeToSystemTime	5.1 and higher	documented
//TzSpecificLocalTimeToSystemTimeEx	6.2 and higher	documented
//UTRegister	4.0 and higher	 
//UTUnRegister	4.0 and higher	 
//UmsThreadYield	6.1 and higher (x64 only)	documented
//UnMapLS	4.0 to 4.90 (Windows only)	 
//UnMapLSFixArray	4.0 to 4.90 (Windows only)	 
//UnhandledExceptionFilter	3.51 and higher	documented
//UninitializeCriticalSection	4.0 to 4.90 (Windows only)	 
//UnlockFile	3.51 and higher	documented
//UnlockFileEx	3.51 and higher	documented
//UnmapViewOfFile	3.51 and higher	documented
//UnmapViewOfFileEx	6.2 and higher	 
//UnregisterApplicationRecoveryCallback	6.0 and higher	documented
//UnregisterApplicationRestart	6.0 and higher	documented
//UnregisterBadMemoryNotification	6.2 and higher	documented
//UnregisterConsoleIME	5.0 and higher	 
//UnregisterStateChangeNotification	6.2 only	 
//UnregisterStateLock	6.2 only	 
//UnregisterWait	5.0 and higher	documented
//UnregisterWaitEx	5.0 and higher	documented
//UnregisterWaitUntilOOBECompleted	6.3 and higher	documented
//UnsubscribeStateChangeNotification	6.2 only	 
//UpdateCalendarDayOfWeek	6.0 and higher	documented
//UpdateProcThreadAttribute	6.0 and higher	documented
//UpdateResourceA	3.51 and higher	documented
//UpdateResourceW	3.51 and higher	documented
//VDMConsoleOperation	3.51 and higher (NT only)	 
//VDMOperationStarted	3.51 and higher (NT only)	 
//ValidateLCType	5.0 to 5.2	 
//ValidateLocale	5.0 to 5.2	 
//VerLanguageNameA	3.51 and higher	documented
//VerLanguageNameW	3.51 and higher	documented
//VerSetConditionMask	5.0 and higher	documented
//VerifyConsoleIoHandle	3.51 and higher (NT only)	 
//VerifyScripts	6.0 and higher	documented
//VerifyVersionInfoA	4.0 from Windows NT 4.0 SP4, and higher (NT only)	documented
//VerifyVersionInfoW	4.0 from Windows NT 4.0 SP4, and higher (NT only)	documented
//VirtualAlloc	3.51 and higher	documented
//VirtualAllocEx	4.0 from Windows NT 4.0, and higher	documented
//VirtualAllocExNuma	6.0 and higher	documented
//VirtualBufferExceptionHandler	3.51 to 5.2 before Windows Server 2003 SP1 (NT only)	 
//VirtualFree	3.51 and higher	documented
//VirtualFreeEx	4.0 from Windows NT 4.0, and higher	documented
//VirtualLock	3.51 and higher	documented
//VirtualProtect	3.51 and higher	documented
//VirtualProtectEx	3.51 and higher	documented
//VirtualQuery	3.51 and higher	documented
//VirtualQueryEx	3.51 and higher	documented
//VirtualUnlock	3.51 and higher	documented
//VxDCall (1)	4.0 to 4.90 (Windows only)	 
//VxDCall1 (2)	4.0 to 4.90 (Windows only)	 
//VxDCall2 (3)	4.0 to 4.90 (Windows only)	 
//VxDCall3 (4)	4.0 to 4.90 (Windows only)	 
//VxDCall4 (5)	4.0 to 4.90 (Windows only)	 
//VxDCall5 (6)	4.0 to 4.90 (Windows only)	 
//VxDCall6 (7)	4.0 to 4.90 (Windows only)	 
//VxDCall7 (8)	4.0 to 4.90 (Windows only)	 
//VxDCall8 (9)	4.0 to 4.90 (Windows only)	 
//W32S_BackTo32 (51)	4.0 to 4.90 (Windows only)	 
//WOWCallback16 (54)	4.0 to 4.90 (Windows only)	documented (WOW32)
//WOWCallback16Ex (55)	4.0 to 4.90 (Windows only)	documented (WOW32)
//WOWDirectedYield16 (67)	4.0 to 4.90 (Windows only)	 
//WOWGetDescriptor (70)	4.0 to 4.90 (Windows only)	 
//WOWGetVDMPointer (56)	4.0 to 4.90 (Windows only)	documented (WOW32)
//WOWGetVDMPointerFix (68)	4.0 to 4.90 (Windows only)	documented (WOW32)
//WOWGetVDMPointerUnfix (69)	4.0 to 4.90 (Windows only)	documented (WOW32)
//WOWGlobalAlloc16 (59)	4.0 to 4.90 (Windows only)	documented (WOW32)
//WOWGlobalAllocLock16 (63)	4.0 to 4.90 (Windows only)	documented (WOW32)
//WOWGlobalFree16 (62)	4.0 to 4.90 (Windows only)	documented (WOW32)
//WOWGlobalLock16 (60)	4.0 to 4.90 (Windows only)	documented (WOW32)
//WOWGlobalLockSize16 (65)	4.0 to 4.90 (Windows only)	documented (WOW32)
//WOWGlobalUnlock16 (61)	4.0 to 4.90 (Windows only)	documented (WOW32)
//WOWGlobalUnlockFree16 (64)	4.0 to 4.90 (Windows only)	documented (WOW32)
//WOWHandle16 (58)	4.0 to 4.90 (Windows only)	documented (WOW32)
//WOWHandle32 (57)	4.0 to 4.90 (Windows only)	documented (WOW32)
//WOWYield16 (66)	4.0 to 4.90 (Windows only)	 
//WTSGetActiveConsoleSessionId	5.1 and higher	documented
//WaitCommEvent	3.51 and higher	documented
//WaitForDebugEvent	3.51 and higher	documented
//WaitForDebugEventEx	10.0 and higher	documentation
//WaitForMultipleObjects	3.51 and higher	documented
//WaitForMultipleObjectsEx	3.51 and higher	documented
//WaitForSingleObject	3.51 and higher	documented
//WaitForSingleObjectEx	3.51 and higher	documented
//WaitForThreadpoolIoCallbacks	6.0 and higher	documented
//WaitForThreadpoolTimerCallbacks	6.0 and higher	documented
//WaitForThreadpoolWaitCallbacks	6.0 and higher	documented
//WaitForThreadpoolWorkCallbacks	6.0 and higher	documented
//WaitNamedPipeA	3.51 and higher	documented
//WaitNamedPipeW	3.51 and higher	documented
//WakeAllConditionVariable	6.0 and higher	documented
//WakeConditionVariable	6.0 and higher	documented
//WerGetFlags	6.0 and higher	documented
//WerGetFlagsWorker	10.0 and higher	 
//WerRegisterFile	6.0 and higher	documented
//WerRegisterFileWorker	6.2 and higher	 
//WerRegisterMemoryBlock	6.0 and higher	documented
//WerRegisterMemoryBlockWorker	6.2 and higher	 
//WerRegisterRuntimeExceptionModule	6.1 and higher	documented
//WerRegisterRuntimeExceptionModuleWorker	6.2 and higher	 
//WerSetFlags	6.0 and higher	documented
//WerSetFlagsWorker	10.0 and higher	 
//WerUnregisterFile	6.0 and higher	documented
//WerUnregisterFileWorker	6.2 and higher	 
//WerUnregisterMemoryBlock	6.0 and higher	documented
//WerUnregisterMemoryBlockWorker	6.2 and higher	 
//WerUnregisterRuntimeExceptionModule	6.1 and higher	documented
//WerUnregisterRuntimeExceptionModuleWorker	6.2 and higher	 
//WerpCleanupMessageMapping	6.0 and higher	 
//WerpGetDebugger	6.2 and higher	 
//WerpInitiateRemoteRecovery	6.0 and higher	 
//WerpLaunchAeDebug	6.2 and higher	 
//WerpNotifyLoadStringResource	6.0 and higher	 
//WerpNotifyLoadStringResourceEx	6.0 and higher	 
//WerpNotifyLoadStringResourceWorker	6.2 and higher	 
//WerpNotifyUseStringResource	6.0 and higher	 
//WerpNotifyUseStringResourceWorker	6.2 and higher	 
//WerpStringLookup	6.0 and higher	 
//Win32HandleToDosFileHandle (21)	4.0 to 4.90 (Windows only)	 
//WinExec	3.51 and higher	documented
//Wow64DisableWow64FsRedirection	5.2 from Windows Server 2003 SP1, and higher	documented
//Wow64EnableWow64FsRedirection	5.2 and higher	documented
//Wow64GetThreadContext	6.0 and higher	documented
//Wow64GetThreadSelectorEntry	6.1 and higher	documented
//Wow64RevertWow64FsRedirection	5.2 from Windows Server 2003 SP1, and higher	documented
//Wow64SetThreadContext	6.0 and higher	documented
//Wow64SuspendThread	6.0 and higher	documented
//WriteConsoleA	3.51 and higher	documented
//WriteConsoleInputA	3.51 and higher	documented
//WriteConsoleInputVDMA	3.51 and higher (NT only)	 
//WriteConsoleInputVDMW	3.51 and higher (NT only)	 
//WriteConsoleInputW	3.51 and higher	documented
//WriteConsoleOutputA	3.51 and higher	documented
//WriteConsoleOutputAttribute	3.51 and higher	documented
//WriteConsoleOutputCharacterA	3.51 and higher	documented
//WriteConsoleOutputCharacterW	3.51 and higher	documented
//WriteConsoleOutputW	3.51 and higher	documented
//WriteConsoleW	3.51 and higher	documented
//WriteFile	3.51 and higher	documented
//WriteFileEx	3.51 and higher	documented
//WriteFileGather	4.0 from Windows NT 4.0 SP3, and higher	documented
//WritePrivateProfileSectionA	3.51 and higher	documented
//WritePrivateProfileSectionW	3.51 and higher	documented
//WritePrivateProfileStringA	3.51 and higher	documented
//WritePrivateProfileStringW	3.51 and higher	documented
//WritePrivateProfileStructA	3.51 and higher	documented
//WritePrivateProfileStructW	3.51 and higher	documented
//WriteProcessMemory	3.51 and higher	documented
//WriteProfileSectionA	3.51 and higher	documented
//WriteProfileSectionW	3.51 and higher	documented
//WriteProfileStringA	3.51 and higher	documented
//WriteProfileStringW	3.51 and higher	documented
//WriteStateAtomValue	6.2 only	 
//WriteStateContainerValue	6.2 only	 
//WriteTapemark	3.51 and higher	documented
//ZombifyActCtx	5.1 and higher	documented
//ZombifyActCtxWorker	6.2 and higher

MultiByteToWideChar	:: (CodePage : UINT, dwFlags : DWORD, lpMultiByteStr : *CHAR, cbMultiByte : INT, lpWideCharStr : *WCHAR, cchWideChar : INT) -> INT #foreign kernel32;
WideCharToMultiByte :: (CodePage : UINT, dwFlags : DWORD, lpWideCharStr : *WCHAR, cchWideChar : INT, lpMultiByteStr : *CHAR, cbMultiByte : INT, lpDefaultChar : *CHAR, lpUsedDefaultChar : *BOOL) -> INT #foreign kernel32;

CP_ACP        : UINT : 0;
CP_OEMCP      : UINT : 1;
CP_MACCP      : UINT : 2;
CP_THREAD_ACP : UINT : 3;
CP_SYMBOL     : UINT : 42;
CP_UTF7       : UINT : 65000;
CP_UTF8       : UINT : 65001;

/*
WC_COMPOSITECHECK :: ;
WC_ERR_INVALID_CHARS :: ;
WC_NO_BEST_FIT_CHARS :: ;

MB_COMPOSITE :: ;
MB_ERR_INVALID_CHARS :: ;
MB_PRECOMPOSED :: ;
MB_USEGLYPHCHARS :: ;
*/

#scope_file

kernel32 :: #foreign_system_library "kernel32";
